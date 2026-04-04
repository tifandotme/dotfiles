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

---@return string?
local function get_source_dir()
  -- chezmoi source-path returns the source directory when no target specified
  -- Works from any directory, returns empty if chezmoi is not configured
  local output = Command("chezmoi")
      :arg({ "source-path" })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :output()

  if output and output.status.success then
    local path = output.stdout:gsub("[%s\r\n]+$", "")
    if path ~= "" then
      return path
    end
  end
  return nil
end

---@param paths table<string, true>
---@param path_style string
---@param include_types string?
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

  local output = cmd
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :output()

  if not output or not output.status.success then
    return
  end

  for line in output.stdout:gmatch("[^\r\n]+") do
    if line ~= "" then
      paths[normalize_path(line)] = true
    end
  end
end

---@return { managed: table<string, true>, encrypted: table<string, true> }
local function get_managed_files()
  local managed = {}
  local encrypted = {}

  -- Support browsing both the destination tree and the chezmoi source tree.
  for _, path_style in ipairs({ "absolute", "source-absolute" }) do
    add_managed_files(managed, path_style)
    add_managed_files(encrypted, path_style, "encrypted")
  end

  return { managed = managed, encrypted = encrypted }
end

---@param state { managed: table<string, true>, encrypted: table<string, true> }
local add = ya.sync(function(st, state)
  ---@cast st State
  st.managed = state.managed
  st.encrypted = state.encrypted
  ui.render()
end)

local remove = ya.sync(function(st)
  ---@cast st State
  st.managed = nil
  st.encrypted = nil
  ui.render()
end)

---@param st State
---@param opts Options
local function setup(st, opts)
  st.managed = nil
  st.encrypted = nil

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
end

---@type UnstableFetcher
local function fetch(_, job)
  -- Check if chezmoi is configured by getting the source directory
  local source_dir = get_source_dir()
  if not source_dir then
    remove()
    return true
  end

  -- Get all managed files (don't pass a path to get everything)
  local managed = get_managed_files()

  -- Add to state
  add(managed)

  return true
end

return { setup = setup, fetch = fetch }
