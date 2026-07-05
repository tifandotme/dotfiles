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
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80,100"

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
  "https://github.com/folke/which-key.nvim",
})
install_fff_binary()
require("which-key").setup()
require("which-key").add({
  { "<leader>b", group = "buffers" },
  { "<leader>f", group = "files" },
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

local function buffer_label(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return "[No Name]"
  end

  return vim.fn.fnamemodify(name, ":~:.")
end

local function pick_buffer()
  vim.ui.select(listed_buffers(), {
    prompt = "Buffers",
    format_item = buffer_label,
  }, function(buf)
    if buf then
      vim.api.nvim_set_current_buf(buf)
    end
  end)
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
map("n", "<leader>bb", "<C-^>", key_opts("Alternate buffer"))
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
map({ "n", "v" }, "<leader>fe", open_yazi, key_opts("File explorer"))

-- Keymaps: git
map({ "n", "v" }, "lg", open_lazygit, key_opts("Lazygit"))

-- Keymaps: LSP
map("n", "<leader>p", function()
  vim.lsp.buf.format({ timeout_ms = 1000 })
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

    if client.name == "vtsls" or client.name == "lua_ls" then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("user-format", {}),
  callback = function(ev)
    vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 1000 })
  end,
})

vim.lsp.config("oxlint", {
  settings = {
    disableNestedConfig = false,
    fixKind = "safe_fix",
    run = "onType",
    unusedDisableDirectives = "deny",
  },
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

vim.lsp.enable({ "vtsls", "oxfmt", "oxlint", "superhtml", "gopls", "stylua", "lua_ls" })
