-- Leaders
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = false
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.breakindentopt = "shift:2"
vim.opt.textwidth = 0
vim.opt.wrapmargin = 0
vim.opt.scrolloff = 5
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.showmatch = true
vim.opt.laststatus = 2

-- Cache Git status briefly; `*` means the repo has uncommitted changes.
local git_status_cache = { root = nil, value = "", expires = 0 }

function _G.statusline_git()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return ""
  end

  local root = vim.fs.root(vim.fs.dirname(path), ".git")
  if not root then
    return ""
  end

  local now = vim.uv.now()
  if git_status_cache.root == root and now < git_status_cache.expires then
    return git_status_cache.value
  end

  local branch = vim
    .system({ "git", "-C", root, "branch", "--show-current" }, { text = true })
    :wait()
  local name = branch.code == 0 and vim.trim(branch.stdout) or ""
  if name == "" then
    local head = vim
      .system({ "git", "-C", root, "rev-parse", "--short", "HEAD" }, { text = true })
      :wait()
    name = head.code == 0 and vim.trim(head.stdout) or ""
  end

  local status = vim.system({ "git", "-C", root, "status", "--porcelain" }, { text = true }):wait()
  if status.code == 0 and status.stdout ~= "" then
    name = name .. "*"
  end

  git_status_cache = { root = root, value = name == "" and "" or name .. " ", expires = now + 2000 }
  return git_status_cache.value
end

vim.opt.statusline = " %f%m%r %= %{v:lua.statusline_git()}%y %l:%c %P "
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80,100"
vim.opt.listchars = { space = "·", tab = "→ ", trail = "·", nbsp = "␣" }

local visual_modes = { v = true, V = true, [string.char(22)] = true }
vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function()
    vim.opt_local.list = visual_modes[vim.fn.mode()] or false
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "YankHighlight", timeout = 200 })
  end,
})

vim.filetype.add({
  pattern = {
    [".*Brewfile%.tmpl"] = "sh",
    [".*%.bash%.tmpl"] = "bash",
    [".*%.json%.tmpl"] = "json",
    [".*%.lua%.tmpl"] = "lua",
    [".*%.md%.tmpl"] = "markdown",
    [".*%.nu%.tmpl"] = "nu",
    [".*%.sh%.tmpl"] = "sh",
    [".*%.toml%.tmpl"] = "toml",
    [".*%.ts%.tmpl"] = "typescript",
    [".*%.ya?ml%.tmpl"] = "yaml",
    [".*%.zsh%.tmpl"] = "zsh",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user-json-indent", { clear = true }),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Theme
local function is_macos_dark()
  if vim.fn.has("macunix") ~= 1 then
    return false
  end

  return vim
    .system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true })
    :wait().stdout
    :match("Dark") ~= nil
end

if is_macos_dark() then
  require("gruber-darker").setup()
else
  vim.opt.background = "light"
  vim.cmd.colorscheme("retrobox")
end

vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#ffff00", fg = "#000000" })

-- Plugins
local function install_fff_binary()
  local ok, download = pcall(require, "fff.download")
  if ok and not vim.uv.fs_stat(download.get_binary_path()) then
    download.download_or_build_binary()
  end
end

vim.g.fff = { lazy_sync = true }

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "fff.nvim" and (kind == "install" or kind == "update") then
      if not ev.data.active then
        vim.cmd.packadd("fff.nvim")
      end
      install_fff_binary()
    end
  end,
})

vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/dmtrKovalenko/fff.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/selimacerbas/live-server.nvim",
  "https://github.com/selimacerbas/markdown-preview.nvim",
  "https://github.com/folke/which-key.nvim",
})
install_fff_binary()
require("which-key").setup({
  preset = "classic",
  win = {
    width = math.huge,
    height = { min = 4, max = 15 },
  },
})
require("which-key").add({
  { "<leader>b", group = "buffers" },
  { "<leader>f", group = "files" },
  { "<leader>m", group = "markdown" },
})

require("markdown_preview").setup({
  default_theme = is_macos_dark() and "dark" or "light",
})

-- Git signs
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")
    local function git_opts(desc)
      return { buffer = bufnr, desc = desc, silent = true }
    end

    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, git_opts("Next hunk"))
    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, git_opts("Previous hunk"))
    vim.keymap.set("n", "dp", gitsigns.reset_hunk, git_opts("Reset hunk"))
    vim.keymap.set("n", "do", gitsigns.preview_hunk, git_opts("Preview hunk"))
  end,
})

-- Features: floating terminals
local function current_dir()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return vim.uv.cwd()
  end

  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "directory" then
    return path
  end

  return vim.fs.dirname(path)
end

local function open_float_term(command, opts)
  opts = opts or {}

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = "rounded",
    style = "minimal",
  })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  vim.keymap.set("t", "<Esc>", close, { buffer = buf, desc = "Close terminal", silent = true })

  vim.fn.jobstart(command, {
    term = true,
    cwd = opts.cwd,
    on_exit = function(_, code)
      vim.schedule(function()
        close()
        if opts.on_exit then
          opts.on_exit(code)
        end
      end)
    end,
  })
  vim.cmd.startinsert()
end

-- Features: files
local function open_yazi()
  local chooser = vim.fn.tempname()
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = current_dir()
  end

  open_float_term({ "yazi", "--chooser-file", chooser, start }, {
    cwd = current_dir(),
    on_exit = function()
      local file = io.open(chooser, "r")
      if not file then
        return
      end

      local selection = file:read("*l")
      file:close()
      os.remove(chooser)

      if selection and selection ~= "" then
        vim.cmd.edit(vim.fn.fnameescape(selection))
      end
    end,
  })
end

-- Features: git
local function git_root()
  local cwd = current_dir()
  local result = vim
    .system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true })
    :wait()
  if result.code == 0 then
    return vim.trim(result.stdout)
  end

  return cwd
end

local function open_lazygit()
  open_float_term({ "lazygit" }, { cwd = git_root() })
end

-- Features: buffers
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
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end

-- Keymaps
local map = vim.keymap.set
local format_buffer

local function key_opts(desc)
  return { desc = desc, silent = true }
end

-- Keymaps: general
map("i", "jj", "<Esc>", key_opts("Exit insert mode"))
map("i", "<C-Space>", "<C-x><C-o>", key_opts("Complete"))
map("n", "<Esc>", "<cmd>nohlsearch<cr>", key_opts("Clear search highlight"))
map("n", "<leader>w", "<cmd>write<cr>", key_opts("Write file"))
map("n", "<leader>r", "<cmd>source ~/.config/nvim/init.lua<cr>", key_opts("Reload config"))
map("n", "U", "<C-r>", key_opts("Redo"))
map({ "n", "v" }, "gh", "0", key_opts("Line start"))
map({ "n", "v" }, "gl", "$", key_opts("Line end"))
map("n", "ge", "G", key_opts("File end"))
map("n", "j", "gj", key_opts("Down by display line"))
map("n", "k", "gk", key_opts("Up by display line"))
map("n", "0", "g0", key_opts("Display line start"))
map("n", "$", "g$", key_opts("Display line end"))
map("n", "q:", ":", key_opts("Command line"))
map("n", "<C-h>", "<C-w>h", key_opts("Window left"))
map("n", "<C-j>", "<C-w>j", key_opts("Window down"))
map("n", "<C-k>", "<C-w>k", key_opts("Window up"))
map("n", "<C-l>", "<C-w>l", key_opts("Window right"))

-- Keymaps: buffers
map("n", "<leader><leader>", pick_buffer, key_opts("Pick buffer"))
map("n", "<A-Tab>", "<C-^>", key_opts("Alternate buffer"))
map("n", "<Tab>", "<cmd>bnext<cr>", key_opts("Next buffer"))
map("n", "<S-Tab>", "<cmd>bprevious<cr>", key_opts("Previous buffer"))
map("n", "<leader>bd", "<cmd>bdelete<cr>", key_opts("Delete buffer"))
map("n", "<leader>bo", delete_other_buffers, key_opts("Delete other buffers"))

-- Keymaps: files
map("n", "<leader>ff", function()
  require("fff").find_files()
end, key_opts("Find files"))
map("n", "<leader>fg", function()
  require("fff").live_grep()
end, key_opts("Live grep"))
map({ "n", "x" }, "<leader>fw", function()
  require("fff").live_grep_under_cursor()
end, key_opts("Grep word"))
map({ "n", "v" }, "<leader>e", open_yazi, key_opts("File explorer"))

-- Keymaps: git
map({ "n", "v" }, "<leader>g", open_lazygit, key_opts("Lazygit"))

-- Keymaps: markdown
map("n", "<leader>mp", "<cmd>MarkdownPreview<cr>", key_opts("Markdown preview"))
map("n", "<leader>mr", "<cmd>MarkdownPreviewRefresh<cr>", key_opts("Refresh markdown preview"))
map("n", "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", key_opts("Stop markdown preview"))

-- Keymaps: LSP
map("n", "<leader>p", function()
  format_buffer(0)
end, key_opts("Format file"))
map("n", "<leader>k", vim.lsp.buf.hover, key_opts("Hover"))
map("n", "gd", vim.lsp.buf.definition, key_opts("Go to definition"))
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, key_opts("Next diagnostic"))
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, key_opts("Previous diagnostic"))

-- Diagnostics
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- LSP
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md
vim.api.nvim_create_user_command("LspClients", function()
  vim.print(vim.lsp.get_clients({ bufnr = 0 }))
end, {})

vim.api.nvim_create_user_command("LspFormatters", function()
  vim.print(vim.tbl_map(function(client)
    return {
      name = client.name,
      format = client:supports_method("textDocument/formatting", 0),
    }
  end, vim.lsp.get_clients({ bufnr = 0 })))
end, {})

vim.api.nvim_create_user_command("LspRestartBuffer", function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    client:stop(true)
  end
  vim.cmd.edit()
end, {})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user-lsp", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
    end
  end,
})

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

function format_buffer(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local path = vim.api.nvim_buf_get_name(bufnr)
  if vim.bo[bufnr].filetype == "bash" or vim.bo[bufnr].filetype == "sh" then
    format_with_command(bufnr, { "shfmt" })
    return
  end
  if vim.bo[bufnr].filetype == "markdown" then
    format_with_command(bufnr, { "oxfmt", "--stdin-filepath", path:gsub("%.tmpl$", "") })
    return
  end
  if vim.bo[bufnr].filetype == "nu" then
    format_with_command(bufnr, { "nufmt", "--stdin" })
    return
  end
  if vim.bo[bufnr].filetype == "svg" then
    format_with_command(bufnr, { "superhtml", "fmt", "--stdin" })
    return
  end

  local formatter = formatters_by_filetype[vim.bo[bufnr].filetype]
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

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("user-format", {}),
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "markdown" then
      return
    end

    format_buffer(ev.buf)
  end,
})

-- oxfmt only starts in Oxfmt-configured or package.json workspaces by default.
-- Fall back so it also formats this repo's standalone JSON files.
vim.lsp.config("oxfmt", {
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    on_dir(vim.fs.root(path, ".git") or vim.fs.dirname(path))
  end,
})

vim.lsp.config("superhtml", {
  cmd = { "superhtml", "lsp" },
  filetypes = { "html", "htm", "shtml", "xml" },
  root_markers = { ".git" },
})

vim.lsp.config("stylua", {
  cmd = { "stylua", "--lsp" },
  filetypes = { "lua", "luau" },
  root_markers = { ".stylua.toml", "stylua.toml", ".git" },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
    },
  },
})

vim.lsp.config("vtsls", {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@effect/language-service",
            location = vim.fn.expand("~/.local/share/bun/install/global/node_modules"),
            enableForWorkspaceTypeScriptVersions = true,
          },
        },
      },
    },
  },
})

vim.lsp.enable({
  "bashls",
  "vtsls",
  "oxfmt",
  "oxlint",
  "superhtml",
  "gopls",
  "jsonls",
  "stylua",
  "tombi",
  "tinymist",
  "lua_ls",
  "nushell",
  "yamlls",
})
