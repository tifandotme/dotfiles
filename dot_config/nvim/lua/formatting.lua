local M = {}

local function format_with_command(bufnr, command, cwd)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, "\n")
  if vim.bo[bufnr].endofline then
    input = input .. "\n"
  end

  local result = vim.system(command, { stdin = input, text = true, cwd = cwd }):wait()
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

local cli_formatter_commands = {
  stylua = function(path)
    return {
      "stylua",
      "--config-path",
      vim.fn.stdpath("config") .. "/stylua.toml",
      "--stdin-filepath",
      path,
      "-",
    }
  end,
}

local viteplus_config_files = {
  "vite.config.ts",
  "vite.config.mts",
  "vite.config.js",
  "vite.config.mjs",
  "vite.config.cts",
  "vite.config.cjs",
}

local function is_viteplus_project(root)
  local package_json = root .. "/package.json"
  if not vim.uv.fs_stat(package_json) then
    return false
  end

  local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
  return ok
    and (
      (package.dependencies or {})["vite-plus"] ~= nil
      or (package.devDependencies or {})["vite-plus"] ~= nil
    )
end

local function command_for_buffer(bufnr, cli_only)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo[bufnr].filetype

  if path ~= "" and (filetype == "typescript" or filetype == "typescriptreact") then
    local config = vim.fs.find(viteplus_config_files, {
      path = vim.fs.dirname(path),
      upward = true,
      type = "file",
    })[1]
    if config then
      local root = vim.fs.dirname(config)
      if is_viteplus_project(root) and vim.fn.executable("vp") == 1 then
        return { "vp", "fmt", "--stdin-filepath", path }, root
      end
    end
  end

  local command = command_formatters[filetype]
  if command then
    return command(path)
  end

  local formatter = formatters_by_filetype[filetype]
  if not formatter then
    return nil
  end

  if path:match("%.tmpl$") then
    local template_command = template_commands[formatter]
    if template_command then
      return template_command(path:gsub("%.tmpl$", ""))
    end
    if cli_only then
      return nil
    end
  end

  if cli_only then
    local formatter_command = cli_formatter_commands[formatter]
    return formatter_command and formatter_command(path) or nil
  end
end

function M.format_buffer_cli(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local command, cwd = command_for_buffer(bufnr, true)
  if not command then
    vim.notify(
      ("No CLI formatter configured for filetype %q"):format(vim.bo[bufnr].filetype),
      vim.log.levels.WARN
    )
    return false
  end

  format_with_command(bufnr, command, cwd)
  return true
end

function M.format_buffer(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local filetype = vim.bo[bufnr].filetype
  local command, cwd = command_for_buffer(bufnr, false)
  if command then
    format_with_command(bufnr, command, cwd)
    return
  end

  local formatter = formatters_by_filetype[filetype]
  if not formatter then
    vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
    return
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
