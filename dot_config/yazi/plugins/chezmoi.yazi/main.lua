--- @since 26.1.1

-- Chezmoi indicator plugin for Yazi
-- Shows an indicator for files managed by chezmoi (dotfiles manager)

---@return string?
local function get_source_dir()
  -- chezmoi source-path returns the source directory when no target specified
  -- Works from any directory, returns empty if chezmoi is not configured
  local output, err = Command("chezmoi")
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

---@return table<string, true> -- Set of managed file paths (absolute paths)
local function get_managed_files()
  local managed = {}

  -- chezmoi managed -p absolute returns all managed entries with absolute paths
  -- Don't pass a path argument to get everything
  local output, err = Command("chezmoi")
      :arg({ "managed", "-p", "absolute" })
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :output()

  if output and output.status.success then
    for line in output.stdout:gmatch("[^\r\n]+") do
      if line ~= "" then
        managed[line] = true
      end
    end
  end

  return managed
end

---@param managed table<string, true>
local add = ya.sync(function(st, managed)
  ---@cast st State
  st.managed = managed
  ui.render()
end)

local remove = ya.sync(function(st)
  ---@cast st State
  st.managed = nil
  ui.render()
end)

---@param st State
---@param opts Options
local function setup(st, opts)
  st.managed = nil

  opts = opts or {}
  opts.order = opts.order or 5000

  -- Icon and styling (hardcoded, no theme.toml needed)
  local sign = ""
  local unmanaged_sign = ""

  Linemode:children_add(function(self)
    if not self._file.in_current then
      return ""
    end

    local managed = st.managed
    if not managed then
      return ""
    end

    -- Check if this specific file is managed (using absolute path)
    local url = self._file.url
    local abs_path = tostring(url)
    local is_managed = managed[abs_path]

    if is_managed then
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

  return false
end

return { setup = setup, fetch = fetch }
