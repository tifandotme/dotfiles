local M = {}

local modes = {
  { id = "n", name = "Normal" },
  { id = "x", name = "Visual" },
  { id = "o", name = "Operator-pending" },
  { id = "i", name = "Insert" },
  { id = "c", name = "Command-line" },
  { id = "t", name = "Terminal" },
}

local function escape(value)
  local result = tostring(value or ""):gsub("|", "\\|"):gsub("\n", " ")
  return result
end

local function format_key(lhs)
  local result = lhs:gsub(" ", "<Space>"):gsub(string.char(22), "<C-v>")
  return result
end

local function description(mapping)
  if mapping.desc and mapping.desc ~= "" then
    return mapping.desc
  end
  if mapping.callback then
    return "Lua callback"
  end
  if mapping.rhs and mapping.rhs ~= "" then
    return mapping.rhs
  end
  return "No description"
end

local function mapping_sort_key(lhs)
  local prefix = lhs:sub(1, 1)
  if prefix ~= "[" and prefix ~= "]" then
    return 1, lhs, 0
  end

  local suffix = lhs:sub(2)
  local group = ({
    ["["] = "section-start",
    ["]"] = "section-end",
  })[lhs] or suffix:lower()
  local rank = prefix == "[" and 1 or 2
  if suffix:match("^%u$") then
    rank = rank + 2
  end
  return 0, group, rank
end

local function get_mappings(mode)
  local mappings = vim.api.nvim_get_keymap(mode.id)
  vim.list_extend(mappings, vim.api.nvim_buf_get_keymap(0, mode.id))
  table.sort(mappings, function(left, right)
    local left_type, left_group, left_rank = mapping_sort_key(left.lhs)
    local right_type, right_group, right_rank = mapping_sort_key(right.lhs)
    if left_type ~= right_type then
      return left_type < right_type
    end
    if left_group ~= right_group then
      return left_group < right_group
    end
    if left_rank ~= right_rank then
      return left_rank < right_rank
    end
    return left.lhs < right.lhs
  end)
  return mappings
end

function M.open()
  local lines = { "# Keymaps", "", "Generated from active Neovim mappings.", "" }

  for _, mode in ipairs(modes) do
    local mappings = get_mappings(mode)
    table.insert(lines, "## " .. mode.name)
    table.insert(lines, "")
    table.insert(lines, "| Key | Description |")
    table.insert(lines, "| --- | --- |")

    local has_rows = false
    for _, mapping in ipairs(mappings) do
      if not mapping.lhs:match("^<Plug>") then
        has_rows = true
        table.insert(
          lines,
          ("| `%s` | %s |"):format(escape(format_key(mapping.lhs)), escape(description(mapping)))
        )
      end
    end

    if not has_rows then
      lines[#lines - 1] = "_No mappings._"
      lines[#lines] = nil
    end
    table.insert(lines, "")
  end

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].filetype = "markdown"
  vim.api.nvim_set_current_buf(buffer)
  if vim.g.mini_clue_configured then
    require("mini.clue").ensure_buf_triggers()
  end
end

function M.setup()
  vim.api.nvim_create_user_command("Keymaps", M.open, {
    desc = "Show active keymaps",
  })
end

return M
