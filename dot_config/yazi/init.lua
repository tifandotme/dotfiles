require("starship"):setup()

-- Starship only runs locally, so over SFTP show the sftp://host/path instead.
Header:children_add(function()
  local cwd = cx.active.current.cwd
  if not cwd.spec.is_regular and not cwd.spec.is_search then
    return ui.Line { ui.Span(tostring(cwd)):fg("blue"), ui.Span(" ") }
  end
  return ""
end, 500, Header.LEFT)
require("full-border"):setup {
  -- Available values: "plain", "rounded"
  set = "plain",
}
require("git"):setup {
  order = 1500,
}
require("folder-rules"):setup()
require("chezmoi"):setup()

-- https://yazi-rs.github.io/docs/configuration/yazi/#manager.linemode
function Linemode:size_and_mtime()
  local time = math.floor(self._file.cha.mtime or 0)
  local time_str
  if time == 0 then
    time_str = ""
  elseif os.date("%Y", time) == os.date("%Y") then
    time_str = os.date("%d/%m", time)
  else
    time_str = os.date("%d/%m/%Y", time)
  end

  local size = self._file:size()
  local text = string.format("%s %s", size and ya.readable_size(size) or "", time_str)
  return ui.Line { ui.Span(text) }
end

-- https://yazi-rs.github.io/docs/tips/#symlink-in-status
Status:children_add(function(self)
  local h = self._current.hovered
  if h and h.link_to then
    return " -> " .. tostring(h.link_to)
  else
    return ""
  end
end, 3300, Status.LEFT)

-- https://yazi-rs.github.io/docs/tips/#user-group-in-status
Status:children_add(function()
  local h = cx.active.current.hovered
  if not h or ya.target_family() ~= "unix" then
    return ""
  end

  return ui.Line {
    ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
    ":",
    ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
    " ",
  }
end, 500, Status.RIGHT)
