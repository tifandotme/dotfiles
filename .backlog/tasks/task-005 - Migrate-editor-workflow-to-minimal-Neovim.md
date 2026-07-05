---
id: TASK-005
title: Migrate editor workflow to minimal Neovim
status: Done
assignee:
  - '@pi'
created_date: '2026-06-28 09:09'
updated_date: '2026-06-28 09:21'
labels: []
dependencies: []
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current Vim one-off editing workflow with a minimal Neovim IDE setup while keeping Zed available during the transition. Neovim should support the trusted Zed formatting/LSP workflow, terminal-native navigation, and the existing Gruber darker visual style.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Neovim config exists under dot_config/nvim with lazy.nvim, nvim-lspconfig, fff.nvim, yazi.nvim, stock LSP behavior, and Zed-like keymaps.
- [x] #2 Gruber darker Zed theme is ported into a separate Neovim Lua colorscheme file.
- [x] #3 Package manifests install Neovim, lua-language-server, and @vtsls/language-server while keeping existing oxfmt/oxlint tooling.
- [x] #4 Nushell aliases make vim invoke nvim, dot_vim/vimrc is removed, and dot_config/zed remains in place.
- [x] #5 Chezmoi dry-run and relevant syntax checks complete without errors.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add minimal Neovim config and separate Gruber darker colorscheme.
2. Wire lazy.nvim plugins: nvim-lspconfig, fff.nvim, and yazi.nvim.
3. Enable LSP servers for vtsls, oxfmt, oxlint, superhtml, gopls, and lua_ls with Zed-like keymaps and focused format-on-save.
4. Update package manifests for neovim, lua-language-server, and @vtsls/language-server.
5. Add Nushell vim-to-nvim alias, remove dot_vim/vimrc, keep Zed config.
6. Run syntax/render checks and chezmoi dry-run.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added minimal Neovim config with lazy.nvim, nvim-lspconfig, fff.nvim, yazi.nvim, built-in LSP completion, Zed-like keymaps, focused format-on-save, and a separate Gruber darker colorscheme. Added Lua static-analysis and formatting config via .luarc.json and stylua.toml.

Updated package manifests for neovim, lua-language-server, stylua, and @vtsls/language-server. Added Nushell vim=nvim alias and removed dot_vim/vimrc while keeping dot_config/zed.

Checks passed: stylua --check dot_config/nvim; luac -p dot_config/nvim/init.lua dot_config/nvim/lua/gruber-darker.lua; lua-language-server --check dot_config/nvim --checklevel Warning; bash -n rendered Bun installer; shellcheck run_onchange_02_install-bun.sh.tmpl; nu source core.nu; chezmoi execute-template dot_Brewfile.tmpl; chezmoi apply --dry-run --force; nvim --headless smoke test.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented the minimal Neovim migration tracked in TASK-005. Added source-managed Neovim config, ported the Gruber darker theme, wired lazy.nvim plugins for LSP, fff, and yazi, added package/install support, aliased vim to nvim, removed the old Vim config, and added Lua formatting/static-analysis support. Zed config remains for transition. Checks passed as listed in implementation notes.
<!-- SECTION:FINAL_SUMMARY:END -->
