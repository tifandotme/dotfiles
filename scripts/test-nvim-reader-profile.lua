local is_box = vim.uv.os_gethostname() == "box"
local is_development_profile = not is_box

assert((vim.fn.exists(":LspClients") == 2) == is_development_profile)
for _, module in ipairs({ "mini.completion", "mini.extra", "mini.surround", "multicursor-nvim" }) do
  assert((package.loaded[module] ~= nil) == is_development_profile, module)
end
assert((package.loaded["mini.map"] ~= nil) == is_development_profile)
assert(package.loaded["mini.pick"] ~= nil)
assert(package.loaded["mini.files"] ~= nil)
local format_mapping = vim.fn.maparg("<Space>p", "n", false, true)
assert(format_mapping.desc == "Format file")
for _, lhs in ipairs({ " ff", " fg", " e" }) do
  assert(vim.fn.maparg(lhs, "n").rhs ~= "", "missing reader mapping: " .. lhs)
end

local format_autocmds = vim.api.nvim_get_autocmds({ event = "BufWritePre", group = "user-config" })
assert((#format_autocmds > 0) == is_development_profile)

if is_box then
  local format_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(
    format_buf,
    vim.fs.joinpath(vim.fn.getcwd(), "dot_config/yazi/init.lua")
  )
  vim.bo[format_buf].filetype = "lua"
  vim.api.nvim_buf_set_lines(
    format_buf,
    0,
    -1,
    false,
    { "local value={", "nested={", "answer='yes',", "},", "}", "print(value.nested.answer)" }
  )
  vim.api.nvim_set_current_buf(format_buf)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(" p", true, false, true), "xt", false)
  local formatted = vim.api.nvim_buf_get_lines(format_buf, 0, -1, false)
  assert(formatted[1] == "local value = {")
  assert(formatted[2] == "  nested = {")
  assert(formatted[3] == '    answer = "yes",')
  assert(formatted[4] == "  },")
  assert(formatted[5] == "}")
  assert(formatted[6] == "print(value.nested.answer)")

  local formatting = require("formatting")
  local unsupported_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[unsupported_buf].filetype = "text"
  local lsp_format = vim.lsp.buf.format
  local called_lsp = false
  local notify = vim.notify
  local notification
  vim.notify = function(message)
    notification = message
  end
  vim.lsp.buf.format = function()
    called_lsp = true
  end
  assert(not formatting.format_buffer_cli(unsupported_buf))
  vim.lsp.buf.format = lsp_format
  vim.notify = notify
  assert(notification == 'No CLI formatter configured for filetype "text"')
  assert(not called_lsp)

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(" mm", true, false, true), "xt", false)
  vim.wait(250, function()
    return package.loaded["mini.map"] ~= nil
  end, 10)
end
assert(package.loaded["mini.map"] ~= nil)

print("Neovim reader/development profile checks passed")
