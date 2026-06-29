local M = {}

local c = {
  bg0 = "#101010",
  bg1 = "#181818",
  bg2 = "#212121",
  bg3 = "#282828",
  bg4 = "#303030",
  fg0 = "#f4f4ff",
  fg1 = "#e4e4ef",
  fg2 = "#828282",
  fg3 = "#606060",
  red = "#ff4f58",
  orange = "#cc8c3c",
  yellow = "#ffdd33",
  yellow_dim = "#ccaa00",
  green = "#73c936",
  cyan = "#95a99f",
  blue = "#96a6c8",
  purple = "#9e95c7",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

function M.setup()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "gruber-darker"
  vim.o.termguicolors = true

  hi("Normal", { fg = c.fg1, bg = c.bg1 })
  hi("NormalFloat", { fg = c.fg1, bg = c.bg2 })
  hi("FloatBorder", { fg = c.bg4, bg = c.bg2 })
  hi("SignColumn", { fg = c.fg2, bg = c.bg1 })
  hi("LineNr", { fg = c.fg2, bg = c.bg1 })
  hi("CursorLine", { bg = "#232323" })
  hi("CursorLineNr", { fg = c.yellow, bg = "#232323", bold = true })
  hi("ColorColumn", { bg = c.bg2 })
  hi("Visual", { bg = "#4a4a4a" })
  hi("Search", { fg = c.bg1, bg = c.yellow })
  hi("IncSearch", { fg = c.bg1, bg = c.yellow })
  hi("MatchParen", { fg = c.yellow, bg = c.bg4, bold = true })
  hi("StatusLine", { fg = c.fg1, bg = c.bg0 })
  hi("StatusLineNC", { fg = c.fg2, bg = c.bg0 })
  hi("WinSeparator", { fg = "#292929", bg = c.bg1 })
  hi("Pmenu", { fg = c.fg1, bg = c.bg2 })
  hi("PmenuSel", { fg = c.fg0, bg = c.bg4 })
  hi("Directory", { fg = c.blue })
  hi("NonText", { fg = c.fg3 })
  hi("SpecialKey", { fg = c.fg3 })

  hi("Comment", { fg = c.orange })
  hi("Constant", { fg = c.cyan, bold = true })
  hi("String", { fg = c.green, italic = true })
  hi("Character", { fg = c.green, italic = true })
  hi("Number", { fg = c.fg1 })
  hi("Boolean", { fg = c.yellow })
  hi("Float", { fg = c.fg1 })
  hi("Identifier", { fg = c.fg1 })
  hi("Function", { fg = c.blue })
  hi("Statement", { fg = c.yellow, bold = true })
  hi("Conditional", { fg = c.yellow, bold = true })
  hi("Repeat", { fg = c.yellow, bold = true })
  hi("Label", { fg = c.yellow })
  hi("Operator", { fg = c.fg1 })
  hi("Keyword", { fg = c.yellow, bold = true })
  hi("Exception", { fg = c.red })
  hi("PreProc", { fg = c.purple })
  hi("Type", { fg = c.fg1 })
  hi("StorageClass", { fg = c.yellow })
  hi("Structure", { fg = c.cyan })
  hi("Special", { fg = c.blue })
  hi("Underlined", { fg = c.green, underline = true })
  hi("Error", { fg = c.red })
  hi("Todo", { fg = c.yellow, bg = c.bg2, bold = true })

  hi("DiagnosticError", { fg = c.red })
  hi("DiagnosticWarn", { fg = c.yellow_dim })
  hi("DiagnosticInfo", { fg = c.cyan })
  hi("DiagnosticHint", { fg = c.fg2 })
  hi("DiagnosticUnderlineError", { sp = c.red, undercurl = true })
  hi("DiagnosticUnderlineWarn", { sp = c.yellow_dim, undercurl = true })
  hi("DiagnosticUnderlineInfo", { sp = c.cyan, undercurl = true })
  hi("DiagnosticUnderlineHint", { sp = c.fg2, undercurl = true })

  hi("@comment", { link = "Comment" })
  hi("@string", { link = "String" })
  hi("@string.escape", { fg = c.green, italic = true })
  hi("@number", { link = "Number" })
  hi("@boolean", { link = "Boolean" })
  hi("@function", { link = "Function" })
  hi("@function.call", { link = "Function" })
  hi("@constructor", { fg = c.yellow, bold = true })
  hi("@keyword", { link = "Keyword" })
  hi("@operator", { link = "Operator" })
  hi("@variable", { link = "Identifier" })
  hi("@variable.member", { fg = c.cyan })
  hi("@property", { fg = c.cyan })
  hi("@type", { link = "Type" })
  hi("@tag", { fg = c.fg1 })
  hi("@tag.attribute", { fg = c.cyan, italic = true })
  hi("@markup.heading", { fg = c.cyan, bold = true })
  hi("@markup.strong", { fg = c.blue, bold = true })
  hi("@markup.italic", { fg = c.blue })
  hi("@markup.link", { fg = c.green, italic = true })
  hi("@markup.link.url", { fg = c.purple })

  vim.g.terminal_color_0 = "#000000"
  vim.g.terminal_color_1 = "#ff6c60"
  vim.g.terminal_color_2 = "#a8ff60"
  vim.g.terminal_color_3 = "#ffffb6"
  vim.g.terminal_color_4 = "#96cbfe"
  vim.g.terminal_color_5 = "#ff73fd"
  vim.g.terminal_color_6 = "#c6c5fe"
  vim.g.terminal_color_7 = "#b5b3aa"
  vim.g.terminal_color_8 = "#6c6c66"
  vim.g.terminal_color_9 = "#ff6c60"
  vim.g.terminal_color_10 = "#a8ff60"
  vim.g.terminal_color_11 = "#ffffb6"
  vim.g.terminal_color_12 = "#96cbfe"
  vim.g.terminal_color_13 = "#ff73fd"
  vim.g.terminal_color_14 = "#c6c5fe"
  vim.g.terminal_color_15 = "#fdfbee"
end

return M
