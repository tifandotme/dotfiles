local function setup()
  ps.sub("cd", function()
    local cwd = cx.active.current.cwd
    if string.lower(tostring(cwd)):find("downloads") then
      ya.emit("sort", { "mtime", reverse = true, dir_first = true })
      ya.emit("linemode", { "mtime" })
    else
      ya.emit("sort", { "extension", reverse = false, dir_first = true })
      ya.emit("linemode", { "none" })
    end
  end)
end

return { setup = setup }
