local M = {}

function M:entry(job)
  local args = job.args or {}
  local cmd = args[1]
  local flag = args[2] -- optional flag like "--template" or "--encrypt"

  local state = ya.sync(function()
    local cwd = cx.active.current.cwd
    local hovered = cx.active.current.hovered
    return {
      cwd = tostring(cwd),
      hovered = hovered and tostring(hovered.url) or nil,
      selected = cx.active.selected,
    }
  end)

  local target = state.hovered
  if not target then
    ya.notify {
      title = "Chezmoi",
      content = "No file selected",
      timeout = 3,
      level = "error",
    }
    return
  end

  if cmd == "add" then
    local chezmoi_args = { "add" }
    if flag then
      table.insert(chezmoi_args, flag)
    end
    table.insert(chezmoi_args, target)

    local output, err = Command("chezmoi"):args(chezmoi_args):output()
    if output then
      local stdout = output.stdout or ""
      local stderr = output.stderr or ""
      if output.status.code == 0 then
        ya.notify {
          title = "Chezmoi Add",
          content = flag and ("Added with " .. flag) or "Added to source state",
          timeout = 3,
          level = "info",
        }
      else
        ya.notify {
          title = "Chezmoi Add Failed",
          content = stderr ~= "" and stderr or "Unknown error",
          timeout = 5,
          level = "error",
        }
      end
    else
      ya.notify {
        title = "Chezmoi Error",
        content = err and tostring(err) or "Failed to run command",
        timeout = 5,
        level = "error",
      }
    end
  elseif cmd == "forget" then
    local output, err = Command("chezmoi"):args({ "forget", target }):output()
    if output and output.status.code == 0 then
      ya.notify {
        title = "Chezmoi Forget",
        content = "Removed from source state",
        timeout = 3,
        level = "info",
      }
    else
      ya.notify {
        title = "Chezmoi Forget Failed",
        content = err and tostring(err) or "Unknown error",
        timeout = 5,
        level = "error",
      }
    end
  elseif cmd == "apply" then
    local output, err = Command("chezmoi"):args({ "apply", target }):output()
    if output and output.status.code == 0 then
      ya.notify {
        title = "Chezmoi Apply",
        content = "Applied to destination",
        timeout = 3,
        level = "info",
      }
    else
      ya.notify {
        title = "Chezmoi Apply Failed",
        content = err and tostring(err) or "Unknown error",
        timeout = 5,
        level = "error",
      }
    end
  elseif cmd == "re-add" then
    local output, err = Command("chezmoi"):args({ "re-add", target }):output()
    if output and output.status.code == 0 then
      ya.notify {
        title = "Chezmoi Re-add",
        content = "Re-added current state",
        timeout = 3,
        level = "info",
      }
    else
      ya.notify {
        title = "Chezmoi Re-add Failed",
        content = err and tostring(err) or "Unknown error",
        timeout = 5,
        level = "error",
      }
    end
  else
    ya.notify {
      title = "Chezmoi",
      content = "Unknown command: " .. tostring(cmd),
      timeout = 3,
      level = "warn",
    }
  end
end

return M
