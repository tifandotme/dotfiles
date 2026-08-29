---
id: TASK-008
title: Simplify Gruber Darker colorscheme loading
status: Done
assignee:
  - '@pi'
created_date: '2026-08-16 11:17'
updated_date: '2026-08-16 11:24'
labels: []
dependencies: []
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why
The local Gruber Darker theme currently has a colorscheme loader in `dot_config/nvim/colors/gruber-darker.lua` and its implementation in `dot_config/nvim/lua/gruber-darker.lua`. For a standalone local colorscheme, this split may be unnecessary indirection.

## Scope
- Review the existing Gruber Darker colorscheme files and its consumer in `dot_config/nvim/init.lua`.
- Consolidate the theme into the conventional Neovim colorscheme location if that is the simplest correct layout.
- Preserve the existing Gruber Darker palette, highlight groups, terminal colors, and dark-mode selection.
- Keep normal `:colorscheme gruber-darker` behavior.

## Cold-start context
- `dot_config/nvim/init.lua` calls `vim.cmd.colorscheme("gruber-darker")`.
- `dot_config/nvim/colors/gruber-darker.lua` currently only calls `require("gruber-darker").setup()`.
- `dot_config/nvim/lua/gruber-darker.lua` contains the palette and highlight definitions.
- TASK-005 introduced the separate Gruber Darker colorscheme during the Neovim migration.

## Out of scope / follow-ups
- Do not assess or refactor the rest of `dot_config/nvim/init.lua`; track that as separate future work.
- Do not change the visual palette or add a third-party theme dependency.
- Do not add a module framework or plugin manager.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The colorscheme has one authoritative implementation in the simplest appropriate Neovim runtime location.
- [x] #2 Gruber Darker still loads through vim.cmd.colorscheme("gruber-darker") and the normal colorscheme runtime path.
- [x] #3 Existing colors, highlights, terminal colors, and dark-mode behavior remain unchanged.
- [x] #4 No unused loader or module file remains after consolidation.
- [x] #5 Lua formatting, syntax, smoke, static-analysis, and chezmoi checks pass.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Run the applicable Lua format, syntax, smoke, and chezmoi dry-run checks from dot_config/nvim/AGENTS.md.
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Compare the current colorscheme loader and implementation against Neovim runtime conventions.
2. Consolidate the two files into the simplest correct colorscheme layout without changing behavior.
3. Remove any now-unused file and verify the colorscheme through the existing init.lua caller.
4. Run the Neovim and chezmoi validation commands.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Moved the full Gruber Darker implementation into `dot_config/nvim/colors/gruber-darker.lua` and removed `dot_config/nvim/lua/gruber-darker.lua`. Updated the Neovim validation references in `dot_config/nvim/AGENTS.md` and `dot_config/nvim/mise.toml`.

Validation passed: `stylua --check dot_config/nvim`, `luac -p dot_config/nvim/init.lua dot_config/nvim/colors/gruber-darker.lua`, `lua-language-server --check dot_config/nvim --checklevel Warning`, `mise run check` from `dot_config/nvim`, `nvim --headless` colorscheme smoke test with highlight assertions, and `chezmoi apply --dry-run --force`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Moved Gruber Darker from a Lua module plus loader into one standard `colors/gruber-darker.lua` colorscheme file. Preserved the palette and runtime behavior, updated validation paths, and verified formatting, syntax, static analysis, Neovim loading, and chezmoi dry-run.
<!-- SECTION:FINAL_SUMMARY:END -->
