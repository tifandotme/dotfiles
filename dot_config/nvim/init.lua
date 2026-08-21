-- --------------------------------- BOOTSTRAP ---------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local user_group = vim.api.nvim_create_augroup("user-config", { clear = true })

-- ------------------------------ EDITOR OPTIONS -------------------------------
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
vim.opt.scrolloff = 5
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.showmatch = true
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80,100"
vim.opt.listchars = { space = "·", tab = "→ ", trail = "·", nbsp = "␣" }

-- -------------------------------- STATUSLINE ---------------------------------
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

-- ------------------------------- AUTOCOMMANDS --------------------------------
local visual_modes = { v = true, V = true, [string.char(22)] = true }
vim.api.nvim_create_autocmd("ModeChanged", {
  group = user_group,
  callback = function()
    vim.opt_local.list = visual_modes[vim.fn.mode()] or false
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = user_group,
  callback = function()
    vim.highlight.on_yank({ higroup = "YankHighlight", timeout = 200 })
  end,
})

vim.filetype.add({
  filename = {
    dot_bashrc = "bash",
    dot_zprofile = "zsh",
    dot_zshenv = "zsh",
    dot_zshrc = "zsh",
  },
  pattern = {
    [".*Brewfile%.tmpl"] = "sh",
    [".*bash_profile"] = "bash",
    [".*%.bash"] = "bash",
    [".*%.bash%.tmpl"] = "bash",
    [".*%.bats"] = "bats",
    [".*%.json%.tmpl"] = "json",
    [".*%.lua%.tmpl"] = "lua",
    [".*%.md%.tmpl"] = "markdown",
    [".*%.mksh"] = "mksh",
    [".*%.nu%.tmpl"] = "nu",
    [".*%.sh%.tmpl"] = "sh",
    [".*%.toml%.tmpl"] = "toml",
    [".*%.ts%.tmpl"] = "typescript",
    [".*%.ya?ml%.tmpl"] = "yaml",
    [".*%.zsh%.tmpl"] = "zsh",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = user_group,
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- -------------------------------- APPEARANCE ---------------------------------
local function is_macos_dark()
  if vim.fn.has("macunix") ~= 1 then
    return false
  end

  return vim
    .system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true })
    :wait().stdout
    :match("Dark") ~= nil
end

local function apply_theme(is_dark)
  vim.opt.background = is_dark and "dark" or "light"
  vim.cmd.colorscheme(is_dark and "gruber-darker" or "retrobox")
  vim.api.nvim_set_hl(0, "YankHighlight", { bg = "#ffff00", fg = "#000000" })
end

local function style_tabline()
  local active_tabline = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  active_tabline.bold = true
  vim.api.nvim_set_hl(0, "MiniTablineCurrent", active_tabline)
  vim.api.nvim_set_hl(0, "MiniTablineModifiedCurrent", active_tabline)
  for _, group in ipairs({
    "MiniTablineVisible",
    "MiniTablineHidden",
    "MiniTablineFill",
    "MiniTablineTabpagesection",
    "MiniTablineTrunc",
  }) do
    vim.api.nvim_set_hl(0, group, { link = "StatusLineNC" })
  end
  vim.api.nvim_set_hl(0, "MiniTablineModifiedVisible", { link = "StatusLine" })
  vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden", { link = "StatusLine" })
end

local is_dark = is_macos_dark()
apply_theme(is_dark)

-- ---------------------------------- PLUGINS ----------------------------------
local function install_fff_binary()
  local ok, download = pcall(require, "fff.download")
  if ok and not vim.uv.fs_stat(download.get_binary_path()) then
    download.download_or_build_binary()
  end
end

vim.g.fff = { lazy_sync = true }

vim.api.nvim_create_autocmd("PackChanged", {
  group = user_group,
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
  "https://github.com/dmtrKovalenko/fff.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/selimacerbas/live-server.nvim",
  "https://github.com/selimacerbas/markdown-preview.nvim",
  "https://github.com/jake-stewart/multicursor.nvim",
  "https://github.com/nvim-mini/mini.nvim",
})
install_fff_binary()

-- --------------------------- PLUGIN CONFIGURATION ----------------------------
require("mini.icons").setup()
require("mini.surround").setup({})
require("mini.pick").setup({})
require("mini.extra").setup({})
require("mini.completion").setup({
  delay = {
    completion = 0,
    info = 100,
    signature = 50,
  },
})
vim.api.nvim_create_autocmd("FileType", {
  group = user_group,
  pattern = "fff_input",
  callback = function(ev)
    vim.b[ev.buf].minicompletion_disable = true
  end,
})
vim.opt.completeopt = { "menuone", "noinsert", "popup" }
local starter = require("mini.starter")
local fff = require("fff")
local actions = starter.sections.builtin_actions()
table.insert(actions, 2, {
  name = "File explorer",
  action = function()
    require("mini.files").open()
  end,
  section = "Builtin actions",
})
table.insert(actions, 3, {
  name = "Find files",
  action = fff.find_files,
  section = "Builtin actions",
})
starter.setup({
  items = {
    actions,
    starter.sections.recent_files(5, true, true),
  },
})
require("mini.files").setup({
  mappings = {
    close = "<Esc>",
  },
  options = {
    permanent_delete = false,
  },
})
vim.api.nvim_create_autocmd("User", {
  group = user_group,
  pattern = "MiniFilesBufferCreate",
  callback = function(ev)
    local buf = ev.data.buf_id
    vim.keymap.set("n", "<Esc>", function()
      if vim.v.hlsearch == 1 then
        vim.cmd.nohlsearch()
      else
        require("mini.files").close()
      end
    end, { buffer = buf, desc = "Clear search or close explorer", nowait = true, silent = true })
  end,
})
require("mini.tabline").setup({})
local minmap = require("mini.map")
minmap.setup({
  integrations = {
    minmap.gen_integration.builtin_search(),
    minmap.gen_integration.diagnostic(),
    minmap.gen_integration.gitsigns(),
  },
})
local function style_minimap()
  local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
  local muted = vim.api.nvim_get_hl(0, { name = "SpecialKey", link = false })
  vim.api.nvim_set_hl(0, "MiniMapNormal", {
    fg = muted.fg or normal_float.fg,
    bg = normal_float.bg,
  })
end

style_minimap()
style_tabline()
vim.api.nvim_create_user_command("ColorsTweak", function()
  require("mini.colors").interactive()
end, {})
if not vim.g.mini_clue_configured then
  local miniclue = require("mini.clue")
  miniclue.setup({
    triggers = {
      { mode = { "n", "x" }, keys = "<Leader>" },
      { mode = "n", keys = "t" },
      { mode = { "n", "x" }, keys = "[" },
      { mode = { "n", "x" }, keys = "]" },
      { mode = "i", keys = "<C-x>" },
      { mode = { "n", "x" }, keys = "g" },
      { mode = { "n", "x" }, keys = "'" },
      { mode = { "n", "x" }, keys = "`" },
      { mode = { "n", "x" }, keys = '"' },
      { mode = { "i", "c" }, keys = "<C-r>" },
      { mode = "n", keys = "<C-w>" },
      { mode = { "n", "x" }, keys = "z" },
    },
    clues = {
      miniclue.gen_clues.square_brackets(),
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows(),
      miniclue.gen_clues.z(),
      { mode = "n", keys = "t", desc = "+Buffers" },
      { mode = { "n", "x" }, keys = "<Leader>f", desc = "+Files" },
      { mode = "n", keys = "<Leader>m", desc = "+Markdown" },
    },
    window = {
      delay = 0,
      config = {
        width = 50,
      },
    },
  })
  vim.g.mini_clue_configured = true
end

local function style_miniclue_next_key()
  if not is_dark then
    local key_color = "#3c3836"
    vim.api.nvim_set_hl(0, "MiniClueNextKey", { fg = key_color, bold = true })
    vim.api.nvim_set_hl(0, "MiniClueSeparator", { fg = key_color })
  end
end

style_miniclue_next_key()

local markdown_preview = require("markdown_preview")
markdown_preview.setup({
  default_theme = is_dark and "dark" or "light",
})

local function refresh_theme()
  local next_is_dark = is_macos_dark()
  if next_is_dark == is_dark then
    return
  end

  is_dark = next_is_dark
  apply_theme(is_dark)
  markdown_preview.setup({
    default_theme = is_dark and "dark" or "light",
  })
  style_tabline()
  style_minimap()
  style_miniclue_next_key()
end

vim.api.nvim_create_autocmd("FocusGained", {
  group = user_group,
  callback = refresh_theme,
})

local appearance_watcher = vim.uv.new_fs_event()
appearance_watcher:start(
  vim.fn.expand("~/.config/theme"),
  {},
  vim.schedule_wrap(function(err, filename)
    if not err and filename == "appearance.changed" then
      refresh_theme()
    end
  end)
)

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = user_group,
  callback = function()
    appearance_watcher:stop()
    appearance_watcher:close()
  end,
})

-- --------------------------------- GIT SIGNS ---------------------------------
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

-- ------------------------------ FEATURE MODULES ------------------------------
local buffers = require("buffers")

-- Keymap helpers
local map = vim.keymap.set
local formatting = require("formatting")
local map_multistep = require("mini.keymap").map_multistep

local function key_opts(desc)
  return { desc = desc, silent = true }
end

local function move_completion(delta, fallback)
  if vim.fn.pumvisible() ~= 1 then
    return fallback
  end

  local info = vim.fn.complete_info()
  local count = #info.items
  if count == 0 then
    return fallback
  end

  local item = info.selected + delta
  if item < 0 then
    item = count - 1
  elseif item >= count then
    item = 0
  end
  vim.api.nvim_select_popupmenu_item(item, false, false, {})
  return ""
end

local multicursor = require("multicursor-nvim")
if not vim.g.multicursor_nvim_configured then
  multicursor.setup()
  map({ "n", "x" }, "<C-n>", function()
    multicursor.matchAddCursor(1)
  end, key_opts("Add next matching cursor"))
  multicursor.addKeymapLayer(function(layer_map)
    layer_map({ "n", "x" }, "<Esc>", multicursor.clearCursors)
  end)
  vim.g.multicursor_nvim_configured = true
end

-- Keymaps
-- General
map("i", "jj", "<Esc>", key_opts("Exit insert mode"))
map("i", "<C-n>", function()
  return move_completion(1, "\14")
end, { expr = true, replace_keycodes = true, desc = "Next completion", silent = true })
map("i", "<C-p>", function()
  return move_completion(-1, "\16")
end, { expr = true, replace_keycodes = true, desc = "Previous completion", silent = true })
map_multistep("i", "<Tab>", { "pmenu_accept" })
map_multistep("i", "<CR>", { "pmenu_accept" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", key_opts("Clear search highlight"))
map("n", "<leader>w", "<cmd>write<cr>", key_opts("Write file"))
map("n", "<leader>r", "<cmd>source ~/.config/nvim/init.lua<cr>", key_opts("Reload config"))
map("n", "<leader>c", "gcc", { remap = true, desc = "Toggle comment", silent = true })
map("x", "<leader>c", "gc", { remap = true, desc = "Toggle comments", silent = true })
map("n", "U", "<C-r>", key_opts("Redo"))
map({ "n", "v" }, "gh", "0", key_opts("Line start"))
map({ "n", "v" }, "gl", "$", key_opts("Line end"))
map("n", "ge", "G", key_opts("File end"))
map("n", "j", "gj", key_opts("Down by display line"))
map("n", "k", "gk", key_opts("Up by display line"))
map("n", "0", "g0", key_opts("Display line start"))
map("n", "$", "g$", key_opts("Display line end"))
map("n", "<A-Down>", "<cmd>move .+1<cr>==", key_opts("Move line down"))
map("n", "<A-Up>", "<cmd>move .-2<cr>==", key_opts("Move line up"))
map("v", "<A-Down>", ":move '>+1<cr>gv=gv", key_opts("Move selection down"))
map("v", "<A-Up>", ":move '<-2<cr>gv=gv", key_opts("Move selection up"))
map("n", "q:", ":", key_opts("Command line"))
map("n", "<C-h>", "<C-w>h", key_opts("Window left"))
map("n", "<C-j>", "<C-w>j", key_opts("Window down"))
map("n", "<C-k>", "<C-w>k", key_opts("Window up"))
map("n", "<C-l>", "<C-w>l", key_opts("Window right"))

-- Buffers
-- t{char} mappings intentionally override native till-character motions.
map("n", "tt", "<cmd>enew<cr>", key_opts("New buffer"))
map("n", "tw", "<cmd>confirm bdelete<cr>", key_opts("Delete buffer"))
map("n", "tr", buffers.open_file_for_rename, key_opts("Rename file in explorer"))
map("n", "to", buffers.delete_other_buffers, key_opts("Delete other buffers"))
map("n", "<leader><leader>", function()
  require("mini.pick").builtin.buffers()
end, key_opts("Pick buffer"))
map("n", "<A-Tab>", "<C-^>", key_opts("Alternate buffer"))
map("n", "<Tab>", "<cmd>bnext<cr>", key_opts("Next buffer"))
map("n", "<S-Tab>", "<cmd>bprevious<cr>", key_opts("Previous buffer"))

-- Files
local function outline_symbols()
  require("mini.extra").pickers.lsp({ scope = "document_symbol" })
end

map("n", "<D-S-o>", outline_symbols, key_opts("Find symbols in current file"))
map("n", "<leader>o", outline_symbols, key_opts("Find symbols in current file"))
map("n", "<leader>h", function()
  require("mini.pick").builtin.help()
end, key_opts("Search help"))
map("n", "<leader>ff", fff.find_files, key_opts("Find files"))
map("n", "<leader>fg", fff.live_grep, key_opts("Live grep"))
map("n", "<leader>fz", function()
  fff.live_grep({ grep = { modes = { "fuzzy", "plain" } } })
end, key_opts("Fuzzy grep"))
map(
  { "n", "x" },
  "<leader>fw",
  fff.live_grep_under_cursor,
  key_opts("Search current word / selection")
)
map("n", "<D-p>", fff.find_files, key_opts("Find files"))
map(
  { "n", "x" },
  "<D-S-f>",
  fff.live_grep_under_cursor,
  key_opts("Search current word / selection")
)
map({ "n", "v" }, "<leader>e", function()
  require("mini.files").open()
end, key_opts("File explorer"))

-- Markdown
map("n", "<leader>mp", "<cmd>MarkdownPreview<cr>", key_opts("Markdown preview"))
map("n", "<leader>mr", "<cmd>MarkdownPreviewRefresh<cr>", key_opts("Refresh markdown preview"))
map("n", "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", key_opts("Stop markdown preview"))
map("n", "<leader>mm", require("mini.map").toggle, key_opts("Toggle minimap"))

-- LSP
map("n", "<leader>p", function()
  formatting.format_buffer(0)
end, key_opts("Format file"))
map("n", "<leader>k", vim.lsp.buf.hover, key_opts("Hover"))
map("n", "gd", vim.lsp.buf.definition, key_opts("Go to definition"))
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, key_opts("Next diagnostic"))
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, key_opts("Previous diagnostic"))

-- ----------------------------- LANGUAGE TOOLING ------------------------------
require("lsp").setup(user_group)
require("formatting").setup(user_group)
