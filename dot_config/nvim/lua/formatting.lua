local M = {}

local function format_with_command(bufnr, command)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, "\n")
  if vim.bo[bufnr].endofline then
    input = input .. "\n"
  end

  local result = vim.system(command, { stdin = input, text = true }):wait()
  if result.code ~= 0 then
    vim.notify(result.stderr, vim.log.levels.ERROR)
    return
  end

  local output = vim.split(result.stdout, "\n", { plain = true })
  if output[#output] == "" then
    table.remove(output)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output)
end

local command_formatters = {
  bash = function(_)
    return { "shfmt", "-ln", "bash" }
  end,
  bats = function(_)
    return { "shfmt", "-ln", "bats" }
  end,
  markdown = function(path)
    return { "oxfmt", "--stdin-filepath", path:gsub("%.tmpl$", "") }
  end,
  mksh = function(_)
    return { "shfmt", "-ln", "mksh" }
  end,
  nu = function(_)
    return { "nufmt", "--stdin" }
  end,
  sh = function(_)
    return { "shfmt" }
  end,
  svg = function(_)
    return { "superhtml", "fmt", "--stdin" }
  end,
  zsh = function(_)
    return { "shfmt", "-ln", "zsh" }
  end,
}

local formatters_by_filetype = {
  css = "oxfmt",
  graphql = "oxfmt",
  handlebars = "oxfmt",
  htm = "superhtml",
  html = "superhtml",
  javascript = "oxfmt",
  javascriptreact = "oxfmt",
  json = "oxfmt",
  json5 = "oxfmt",
  jsonc = "oxfmt",
  less = "oxfmt",
  lua = "stylua",
  luau = "stylua",
  scss = "oxfmt",
  shtml = "superhtml",
  toml = "tombi",
  typescript = "oxfmt",
  typescriptreact = "oxfmt",
  vue = "oxfmt",
  xml = "superhtml",
  yaml = "oxfmt",
}

local template_commands = {
  oxfmt = function(path)
    return { "oxfmt", "--stdin-filepath", path }
  end,
  tombi = function(path)
    return { "tombi", "format", "--stdin-filename", path, "-" }
  end,
}

function M.format_buffer(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local path = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local command = command_formatters[filetype]
  if command then
    format_with_command(bufnr, command(path))
    return
  end

  local formatter = formatters_by_filetype[filetype]
  if not formatter then
    vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
    return
  end

  if path:match("%.tmpl$") then
    local command = template_commands[formatter]
    if command then
      format_with_command(bufnr, command(path:gsub("%.tmpl$", "")))
      return
    end
  end

  vim.lsp.buf.format({
    bufnr = bufnr,
    timeout_ms = 1000,
    filter = function(client)
      return client.name == formatter
    end,
  })
end

function M.setup(user_group)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = user_group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "markdown" then
        return
      end

      M.format_buffer(ev.buf)
    end,
  })
end

return M
