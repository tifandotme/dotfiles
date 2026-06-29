vim.g.mapleader = " "
vim.g.maplocalleader = " "

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

require("gruber-darker").setup()

local function install_fff_binary()
  local ok, download = pcall(require, "fff.download")
  if ok and not vim.uv.fs_stat(download.get_binary_path()) then
    download.download_or_build_binary()
  end
end

vim.g.fff = { lazy_sync = true }
vim.g.loaded_netrwPlugin = 1

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
  "https://github.com/mikavilpas/yazi.nvim",
})
install_fff_binary()

require("gitsigns").setup({
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")
    local git_opts = { buffer = bufnr, silent = true }

    vim.keymap.set("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, git_opts)
    vim.keymap.set("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, git_opts)
    vim.keymap.set("n", "dp", gitsigns.reset_hunk, git_opts)
    vim.keymap.set("n", "do", gitsigns.preview_hunk, git_opts)
  end,
})

require("yazi").setup({
  open_for_directories = true,
  keymaps = { show_help = "<f1>" },
})

local map = vim.keymap.set
local opts = { silent = true }

map("i", "jj", "<Esc>", opts)
map("i", "<C-Space>", "<C-x><C-o>", opts)
map("n", "<Esc>", "<cmd>nohlsearch<cr>", opts)
map("n", "<leader>w", "<cmd>write<cr>", opts)
map("n", "<leader>r", "<cmd>source ~/.config/nvim/init.lua<cr>", opts)
map("n", "<leader>f", function()
  vim.lsp.buf.format({
    timeout_ms = 1000,
    filter = function(client)
      return client.name == "oxfmt" or client.name == "superhtml"
    end,
  })
end, opts)
map({ "n", "v" }, "<leader>c", "gc", { remap = true, silent = true })
map("n", "ff", function()
  require("fff").find_files()
end, opts)
map("n", "fg", function()
  require("fff").live_grep()
end, opts)
map({ "n", "x" }, "fw", function()
  require("fff").live_grep_under_cursor()
end, opts)
map({ "n", "v" }, "<leader>-", "<cmd>Yazi<cr>", opts)
map("n", "U", "<C-r>", opts)
map({ "n", "v" }, "gh", "0", opts)
map({ "n", "v" }, "gl", "$", opts)
map("n", "ge", "G", opts)
map("n", "j", "gj", opts)
map("n", "k", "gk", opts)
map("n", "0", "g0", opts)
map("n", "$", "g$", opts)
map("n", "q:", ":", opts)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

map("n", "<leader>k", vim.lsp.buf.hover, opts)
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, opts)
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, opts)

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user-lsp", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end

    if client.name == "oxfmt" or client.name == "superhtml" then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("user-format", { clear = false }),
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1000 })
        end,
      })
    end
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

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
    },
  },
})

vim.lsp.enable({ "vtsls", "oxfmt", "oxlint", "superhtml", "gopls", "lua_ls" })
