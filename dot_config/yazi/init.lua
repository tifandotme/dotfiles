require("starship"):setup()
require("full-border"):setup {
  -- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
  type = ui.Border.PLAIN,
}
require("folder-rules"):setup()

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
  return string.format("%s %s", size and ya.readable_size(size) or "", time_str)
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
