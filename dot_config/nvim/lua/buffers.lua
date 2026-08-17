local function listed_buffers()
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())
end

local function listed_file_buffers()
  return vim.tbl_filter(function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    return name ~= "" and vim.fn.filereadable(name) == 1
  end, listed_buffers())
end

local function fff_buffer_item(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local display_path = vim.fn.fnamemodify(path, ":~:.")
  local stat = vim.uv.fs_stat(path) or {}

  return {
    bufnr = buf,
    path = path,
    relative_path = display_path:sub(1, 1) == "~" and path or display_path,
    name = vim.fn.fnamemodify(path, ":t"),
    directory = vim.fn.fnamemodify(display_path, ":h"),
    extension = vim.fn.fnamemodify(path, ":e"),
    size = stat.size or 0,
    modified = stat.mtime and stat.mtime.sec or 0,
  }
end

local function set_buffer_for_action(buf, action)
  if action == "split" then
    vim.cmd.split()
  elseif action == "vsplit" then
    vim.cmd.vsplit()
  elseif action == "tab" then
    vim.cmd.tabnew()
  end
  vim.api.nvim_set_current_buf(buf)
end

local function pick_buffer()
  local ok, picker_ui = pcall(require, "fff.picker_ui.picker_ui")
  if not ok then
    vim.notify("Failed to load FFF picker UI: " .. picker_ui, vim.log.levels.ERROR)
    return
  end
  if picker_ui.state.active then
    return
  end

  -- FFF has no public custom-source API, so the buffer picker temporarily
  -- replaces these internals and restores them when it closes.
  local file_picker = require("fff.file_picker")
  local original = {
    search = file_picker.search_files_paginated,
    metadata = file_picker.get_search_metadata,
    score = file_picker.get_file_score,
    close = picker_ui.close,
  }
  local last_total = 0

  local function restore()
    file_picker.search_files_paginated = original.search
    file_picker.get_search_metadata = original.metadata
    file_picker.get_file_score = original.score
    picker_ui.close = original.close
  end

  file_picker.search_files_paginated = function(query, _, _, _, page_index, page_size)
    local items = vim.tbl_map(fff_buffer_item, listed_file_buffers())
    if query and query ~= "" then
      items = vim.fn.matchfuzzypos(items, query, { key = "relative_path" })[1]
    end

    last_total = #items
    page_index = page_index or 0
    page_size = page_size or #items
    local start = page_index * page_size + 1
    return vim.list_slice(items, start, start + page_size - 1)
  end

  file_picker.get_search_metadata = function()
    return { total_matched = last_total, total_files = last_total }
  end
  file_picker.get_file_score = function()
    return nil
  end
  picker_ui.close = function(...)
    restore()
    return original.close(...)
  end

  local opened = picker_ui.open({
    title = "Buffers",
    prompt = "Buffers> ",
    on_submit = function(item, ctx)
      set_buffer_for_action(item.bufnr, ctx.action)
    end,
  })
  if not opened and not picker_ui.state.active then
    restore()
  end
end

local function delete_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(listed_buffers()) do
    if buf ~= current then
      vim.cmd(("confirm bdelete %d"):format(buf))
    end
  end
end

local function open_file_for_rename()
  local path = vim.api.nvim_buf_get_name(0)
  require("mini.files").open(path ~= "" and path or nil)
end

return {
  pick_buffer = pick_buffer,
  delete_other_buffers = delete_other_buffers,
  open_file_for_rename = open_file_for_rename,
}
