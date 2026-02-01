local M = {}

local get_state = ya.sync(function()
  local hovered = cx.active.current.hovered
  return hovered and tostring(hovered.url) or nil
end)

local function run_chezmoi(chezmoi_args, success_msg, fail_title)
  local cmd = Command("chezmoi")
  for _, arg in ipairs(chezmoi_args) do
    cmd = cmd:arg(arg)
  end
  local output, err = cmd:output()
  if not output then
    ya.notify {
      title = "Chezmoi Error",
      content = "Failed to run: " .. tostring(err),
      timeout = 5,
      level = "error",
    }
    return
  end

  if output.status.success then
    ya.notify {
      title = "Chezmoi",
      content = success_msg,
      timeout = 3,
      level = "info",
    }
  else
    ya.notify {
      title = fail_title,
      content = output.stderr ~= "" and output.stderr or ("Exit code: " .. tostring(output.status.code)),
      timeout = 5,
      level = "error",
    }
  end
end

function M:entry(job)
  local args = job.args or {}
  local cmd = args[1]
  local flag = args[2]

  local target = get_state()

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
    local chezmoi_args = { "add", "--force" }
    if flag then
      table.insert(chezmoi_args, flag)
    end
    table.insert(chezmoi_args, target)
    run_chezmoi(chezmoi_args, flag and ("Added with " .. flag) or "Added to source state", "Chezmoi Add Failed")
  elseif cmd == "forget" then
    run_chezmoi({ "forget", "--force", target }, "Removed from source state", "Chezmoi Forget Failed")
  elseif cmd == "apply" then
    run_chezmoi({ "apply", "--force", target }, "Applied to destination", "Chezmoi Apply Failed")
  elseif cmd == "re-add" then
    run_chezmoi({ "re-add", "--force", target }, "Re-added current state", "Chezmoi Re-add Failed")
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
