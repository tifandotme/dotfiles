-- Run from the repository root: lua scripts/test-yazi-chezmoi.lua
local state, command_state = {}, {}
local now, calls, fail, during_scan = 100, 0, false, nil
local managed = { "/home/test/plain", "/home/test/secret" }
local encrypted = { "/home/test/secret" }
local subscriptions, pending = {}, {}
local indicator
local files, cache_path = {}, nil
local write_fail = false

Url = function(path)
  return setmetatable({ parent = path:match("^(.*)/") }, { __tostring = function() return path end })
end
io = {
  open = function(path)
    cache_path = path
    if not files[path] then return nil end
    return { read = function() return files[path] end, close = function() end }
  end,
}
fs = {
  create = function() return true end,
  unique = function(_, path) return Url(tostring(path) .. ".tmp") end,
  write = function(path, data)
    if write_fail then return false end
    files[tostring(path)] = data
    return true
  end,
  rename = function(from, to)
    files[tostring(to)] = files[tostring(from)]
    files[tostring(from)] = nil
    return true
  end,
  remove = function(_, path) files[tostring(path)] = nil end,
}

ya = {
  time = function() return now end,
  sync = function(callback)
    local owner = state
    return function(...) return callback(owner, ...) end
  end,
  throttle = function() end,
  co = coroutine.create,
  emit = function(action, args)
    assert(action == "plugin" and args[1] == "chezmoi")
    pending[#pending + 1] = args
  end,
  notify = function() end,
}
ps = {
  sub = function(kind, callback) subscriptions[kind] = callback end,
  pub = function(kind, value) subscriptions[kind](value) end,
}
ui = {
  render = function() end,
  Span = function(text) return text end,
}
Linemode = { children_add = function(_, callback) indicator = callback end }
cx = { active = { current = { hovered = { url = "/home/test/new" } } } }
Command = setmetatable({ PIPED = 1 }, {
  __call = function()
    local cmd = { args = {} }
    function cmd:arg(args)
      if type(args) == "table" then
        for _, arg in ipairs(args) do
          self.args[#self.args + 1] = arg
        end
      else
        self.args[#self.args + 1] = args
      end
      return self
    end
    function cmd:stdout() return self end
    function cmd:stderr() return self end
    function cmd:output()
      if self.args[1] == "source-path" then
        return { status = { success = true }, stdout = "/source\n" }
      end
      if self.args[1] ~= "managed" then
        return { status = { success = not fail }, stdout = "", stderr = "failed" }
      end
      calls = calls + 1
      if during_scan then
        local callback = during_scan
        during_scan = nil
        callback()
      end
      local args = table.concat(self.args, " ")
      local paths = args:find("encrypted") and encrypted or managed
      local output = {}
      for _, path in ipairs(paths) do
        output[#output + 1] = args:find("source%-absolute") and ("/source" .. path) or path
      end
      return { status = { success = not fail }, stdout = table.concat(output, "\n") }
    end
    return cmd
  end,
})

local function plugin()
  return dofile("dot_config/yazi/plugins/chezmoi.yazi/main.lua")
end

local function fetch()
  -- Yazi isolates each async invocation; only ya.sync state persists.
  local p = plugin()
  local result = p.fetch(p, { files = { "one", "two" } })
  if type(result) == "thread" then
    while coroutine.status(result) ~= "dead" do
      local ok, err = coroutine.resume(result)
      assert(ok, err)
    end
  end
end

local function sign(path)
  return indicator { _file = { in_current = true, path = path } }
end

plugin().setup(state)
fetch()
assert(sign("/home/test/plain") == "")
assert(sign("/home/test/secret") == "󰌾")
assert(sign("/source/home/test/plain/") == "")
assert(sign("/source/home/test/secret") == "󰌾")
assert(sign("/home/test/unmanaged") == " ")

local cold_calls = calls
now = 129.99
fetch()
assert(calls == cold_calls, "a warm batch must not launch chezmoi")

now = 130
managed[#managed + 1] = "/home/test/new"
during_scan = function() fetch() end
fetch()
assert(calls == cold_calls + 4, "concurrent batches must share one refresh")
assert(sign("/home/test/new") == "", "expired cache must pick up external changes")

now = 160
fail = true
fetch()
assert(sign("/home/test/new") == "", "failed scans must retain the last good index")
local failed_calls = calls
fetch()
assert(calls == failed_calls, "failed scans must back off")
fail = false

state, command_state = command_state, state
local command = dofile("dot_config/yazi/plugins/chezmoi-cmd.yazi/main.lua")
state, command_state = command_state, state
local function action()
  command:entry { args = { "forget" } }
  while #pending > 0 do
    table.remove(pending, 1)
    plugin().entry()
  end
end

table.remove(managed)
action()
assert(sign("/home/test/new") == " ", "successful actions must refresh before expiry")
fail = true
local before_failure = calls
action()
assert(calls == before_failure, "failed actions must not invalidate the cache")
fail = false

now = 190
during_scan = function()
  managed[#managed + 1] = "/home/test/later"
  action()
end
fetch()
fetch()
assert(sign("/home/test/later") == "", "in-flight scans must not swallow invalidation")

local before_restart = calls
state = {}
plugin().setup(state)
assert(sign("/home/test/later") == "", "reopening Yazi must show saved icons before scanning")
assert(sign("/source/home/test/secret") == "󰌾", "saved source paths must retain encrypted icons")
assert(calls == before_restart, "loading saved icons must not launch chezmoi")
managed, encrypted = {}, {}
during_scan = function()
  assert(sign("/home/test/later") == "", "saved icons must remain visible during refresh")
end
fetch()
assert(sign("/home/test/later") == " ", "startup refresh must replace stale saved icons")

files[cache_path] = "broken cache"
state = {}
plugin().setup(state)
assert(sign("/home/test/later") == "", "a corrupt cache must fall back to scanning")
managed, encrypted = { "/home/test/secret" }, { "/home/test/secret" }
write_fail = true
fetch()
assert(sign("/home/test/secret") == "󰌾", "cache write failure must not prevent live icons")
assert(files[cache_path] == "broken cache", "failed writes must not replace the saved cache")
print("Yazi chezmoi: persistent icons, refresh, expiry, concurrency, and failure checks passed")
