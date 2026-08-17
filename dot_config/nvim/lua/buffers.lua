local function listed_buffers()
  return vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())
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
  delete_other_buffers = delete_other_buffers,
  open_file_for_rename = open_file_for_rename,
}
