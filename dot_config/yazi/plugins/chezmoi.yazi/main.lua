--- @since 26.1.1

-- Chezmoi indicator plugin for Yazi
-- Shows indicators for plain and encrypted chezmoi-managed files

---@param path string
---@return string
local function normalize_path(path)
  if path == "/" then
    return path
  end

  return path:gsub("/+$", "")
end

local cache_header = "chezmoi-indicators-v1\n"

local function cache_path()
  return (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/yazi/chezmoi-indicators"
end

local function read_cache()
  local file = io.open(cache_path(), "r")
  if not file then return nil end
  local data = file:read("*a")
  file:close()
  if not data or data:sub(1, #cache_header) ~= cache_header then return nil end

  local state = { managed = {}, encrypted = {} }
  for line in data:sub(#cache_header + 1):gmatch("[^\n]+") do
    local kind, path = line:match("^([me])(/.*)$")
    if not kind then return nil end
    state[kind == "m" and "managed" or "encrypted"][normalize_path(path)] = true
  end
  return state
end

local function write_cache(state)
  local url = Url(cache_path())
  if not fs.create("dir_all", url.parent) then return end
  local temporary = fs.unique("file", Url(tostring(url) .. ".tmp"))
  if not temporary then return end

  local lines = { cache_header:sub(1, -2) }
  for kind, paths in pairs({ m = state.managed, e = state.encrypted }) do
    for path in pairs(paths) do
      lines[#lines + 1] = kind .. path
    end
  end
  if not fs.write(temporary, table.concat(lines, "\n") .. "\n") or not fs.rename(temporary, url) then
    fs.remove("file", temporary)
  end
end

---@param paths table<string, true>
---@param path_style string
---@param include_types string?
---@return boolean
local function add_managed_files(paths, path_style, include_types)
  local args = { "managed" }
  if include_types and include_types ~= "" then
    table.insert(args, "--include")
    table.insert(args, include_types)
  end
  table.insert(args, "-p")
  table.insert(args, path_style)

  local cmd = Command("chezmoi")
  for _, arg in ipairs(args) do
    cmd = cmd:arg(arg)
  end

  local output = cmd:stdout(Command.PIPED):stderr(Command.PIPED):output()

  if not output or not output.status.success then
    return false
  end

  for line in output.stdout:gmatch("[^\r\n]+") do
    if line ~= "" then
      paths[normalize_path(line)] = true
    end
  end
  return true
end

---@return { managed: table<string, true>, encrypted: table<string, true> }?
local function get_managed_files()
  local managed = {}
  local encrypted = {}

  -- Support browsing both the destination tree and the chezmoi source tree.
  for _, path_style in ipairs({ "absolute", "source-absolute" }) do
    if not add_managed_files(managed, path_style) or not add_managed_files(encrypted, path_style, "encrypted") then
      return nil
    end
  end

  return { managed = managed, encrypted = encrypted }
end

local claim = ya.sync(function(st)
  if st.refreshing or ya.time() < st.refresh_at then
    return nil
  end
  st.refreshing = true
  return st.generation
end)

local add = ya.sync(function(st, generation, state)
  st.refreshing = false
  if generation ~= st.generation then
    return
  end
  -- ponytail: external changes can lag by 30s; use source watchers if that becomes limiting.
  st.refresh_at = ya.time() + 30
  if state then
    st.managed = state.managed
    st.encrypted = state.encrypted
    ui.render()
  end
  return state ~= nil
end)

---@param st State
---@param opts Options
local function setup(st, opts)
  local cached = read_cache()
  st.managed = cached and cached.managed or nil
  st.encrypted = cached and cached.encrypted or nil
  st.refresh_at = 0
  st.refreshing = false
  st.generation = 0

  ps.sub("chezmoi-refresh", function()
    st.refresh_at = 0
    st.generation = st.generation + 1
    ya.emit("plugin", { "chezmoi" })
  end)

  opts = opts or {}
  opts.order = opts.order or 5000

  -- Icon and styling (hardcoded, no theme.toml needed)
  local sign = ""
  local encrypted_sign = "󰌾"
  local unmanaged_sign = ""

  Linemode:children_add(function(self)
    if not self._file.in_current then
      return ""
    end

    local managed = st.managed
    local encrypted = st.encrypted
    if not managed or not encrypted then
      return ""
    end

    -- Compare against Yazi's normalized filesystem path, not the raw URL object.
    local abs_path = normalize_path(tostring(self._file.path))
    local is_encrypted = encrypted[abs_path]
    local is_managed = managed[abs_path]

    if is_encrypted then
      return ui.Span("" .. encrypted_sign)
    elseif is_managed then
      -- Always return with style to ensure consistent rendering
      -- (border radius issue is a Yazi limitation with children_add)
      return ui.Span("" .. sign)
    elseif unmanaged_sign ~= "" then
      return ui.Span("" .. unmanaged_sign)
    else
      -- Return spaces to maintain alignment with managed files
      return ui.Span(" ")
    end
  end, opts.order)
  ya.emit("plugin", { "chezmoi" })
end

local function refresh()
  local generation = claim()
  if generation ~= nil then
    local state = get_managed_files()
    if add(generation, state) then
      write_cache(state)
    end
  end
end

---@type UnstableFetcher
local function fetch_compact(self, job)
  refresh()
  if ya.throttle then
    return ya.co(function()
      for _, file in ipairs(job.files) do
        coroutine.yield(file, { retry = true })
      end
    end)
  else
    return true
  end
end

return { setup = setup, fetch = fetch_compact, entry = refresh }
