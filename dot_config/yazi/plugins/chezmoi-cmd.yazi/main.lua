local M = {}

local get_target = ya.sync(function()
  local hovered = cx.active.current.hovered
  return hovered and tostring(hovered.url) or nil
end)

local function notify(title, content, level)
  ya.notify { title = title, content = content, timeout = level == "error" and 5 or 3, level = level }
end

local function run_chezmoi(args, success_msg)
  local cmd = Command("chezmoi")
  for _, arg in ipairs(args) do
    cmd = cmd:arg(arg)
  end

  local output, err = cmd:output()
  if not output then
    return notify("Chezmoi", "Failed: " .. tostring(err), "error")
  end

  if output.status.success then
    notify("Chezmoi", success_msg, "info")
  else
    notify("Chezmoi", output.stderr ~= "" and output.stderr or ("Exit " .. output.status.code), "error")
  end
end

local commands = {
  add = { msg = "Added to source state" },
  forget = { msg = "Removed from source state" },
  apply = { msg = "Applied to destination" },
  ["re-add"] = { msg = "Re-added current state" },
}

function M:entry(job)
  local args = job.args or {}
  local cmd_name = args[1]

  -- Check for flags as named arguments (e.g., --encrypt becomes args.encrypt)
  local flag = nil
  if args.template then
    flag = "--template"
  elseif args.encrypt then
    flag = "--encrypt"
  elseif args[2] and string.sub(args[2], 1, 2) == "--" then
    flag = args[2]
  end

  local target = get_target()
  if not target then
    return notify("Chezmoi", "No file selected", "error")
  end

  local cmd_info = commands[cmd_name]
  if not cmd_info then
    return notify("Chezmoi", "Unknown command: " .. tostring(cmd_name), "warn")
  end

  local chezmoi_args = { cmd_name, "--force" }
  if flag then
    table.insert(chezmoi_args, flag)
  end
  table.insert(chezmoi_args, target)

  local msg = (cmd_name == "add" and flag) and ("Added with " .. flag) or cmd_info.msg
  run_chezmoi(chezmoi_args, msg)
end

return M
