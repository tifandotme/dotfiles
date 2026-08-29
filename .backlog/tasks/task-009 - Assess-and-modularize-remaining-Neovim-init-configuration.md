---
id: TASK-009
title: Assess and modularize remaining Neovim init configuration
status: Done
assignee:
  - '@pi'
created_date: '2026-08-16 11:22'
updated_date: '2026-08-16 16:09'
labels: []
dependencies: []
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why
`dot_config/nvim/init.lua` contains several unrelated responsibilities beyond the Gruber Darker colorscheme. A focused assessment can reduce future maintenance cost without splitting small, one-use configuration into shallow modules.

## Scope
- Review the remaining `dot_config/nvim/init.lua` after the Gruber Darker colorscheme move.
- Identify cohesive sections that benefit from focused Lua modules under `dot_config/nvim/lua/`.
- Extract only modules with a clear maintenance, locality, or reuse benefit; keep simple configuration inline.
- Preserve current startup behavior, plugin setup, keymaps, statusline, formatting, diagnostics, LSP behavior, theme switching, and autocommands.

## Cold-start context
- Main entrypoint: `dot_config/nvim/init.lua`.
- The Gruber Darker colorscheme is handled separately by TASK-008.
- Current init responsibilities include options and autocommands, Git statusline support, theme detection and tabline styling, `vim.pack` and plugin setup, buffer/file picker features, keymaps, diagnostics, LSP configuration, and formatter dispatch.
- Existing validation commands are listed in `dot_config/nvim/AGENTS.md`.

## Out of scope / follow-ups
- Do not change user-facing keybindings, plugin choices, formatter commands, LSP servers, or visual design unless required to preserve behavior during extraction.
- Do not split code only to reduce line count.
- Do not refactor the Gruber Darker colorscheme; see TASK-008.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The whole remaining init.lua has a documented module-boundary assessment, including sections intentionally left inline.
- [x] #2 Only cohesive sections with a clear maintenance, locality, or reuse benefit are moved into focused Lua modules.
- [x] #3 The resulting init.lua remains a readable orchestration entrypoint without speculative abstractions.
- [x] #4 Neovim behavior remains unchanged, including startup, plugins, keymaps, statusline, formatting, diagnostics, LSP, theme switching, and autocommands.
- [x] #5 Lua formatting, syntax, smoke, static-analysis, and chezmoi checks pass.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Record the module-boundary assessment and verification evidence in the task.
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Treat `dot_config/nvim/init.lua` as an orchestration entrypoint and document the full boundary assessment: extract only buffers, formatting, and LSP; keep leaders, options, autocommands, theme lifecycle, plugin bootstrap, Gitsigns, keymaps, and the Git statusline inline. Keep the statusline inline because its global `statusline_git()` contract is single-use and extraction would add indirection.
2. Extract buffer discovery, FFF buffer-picker integration, restoration logic, and buffer actions into `lua/buffers.lua`; export only callbacks needed by keymaps.
3. Extract external/LSP formatter dispatch and format-on-save into `lua/formatting.lua`; preserve template handling, synchronous command behavior, markdown exclusion, and `format_buffer` use.
4. Extract diagnostics, LSP commands, attach completion, server configuration, and server enablement into `lua/lsp.lua`; preserve exact servers, settings, commands, and shared augroup behavior.
5. Update `init.lua` to require the focused modules with minimal wiring, preserving plugin order, reload behavior, keymaps, statusline, theme switching, and autocommands.
6. Verify with the Neovim formatting, all-Lua syntax, static-analysis, startup smoke, targeted headless behavior assertions, and chezmoi dry-run checks from `dot_config/nvim/AGENTS.md`; record the assessment and evidence in task notes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Module-boundary assessment: extracted three cohesive responsibilities. `buffers.lua` owns buffer discovery, FFF buffer-picker adaptation and restoration, and buffer actions. `formatting.lua` owns external formatter dispatch, template handling, LSP formatter selection, and format-on-save. `lsp.lua` owns diagnostics, LSP user commands, attach-time completion, server configuration, and enablement.

Intentionally left inline: leaders and the shared augroup, editor options, mode/yank/filetype autocommands, theme detection and switching, tabline and markdown-preview lifecycle, plugin bootstrap, Gitsigns setup, and user-facing keymaps. The Git statusline also remains inline because its single-use global `statusline_git()` contract would add indirection without a maintenance or reuse benefit.

Implemented minimal module wiring in `init.lua`; extracted modules reuse the existing `user-config` augroup and preserve plugin order, keymaps, formatter behavior, LSP settings, theme behavior, statusline, and autocommands. Updated the Lua syntax validation commands to include all modules.

Validation passed: `stylua --check dot_config/nvim`, `luac -p` for every Lua file, `lua-language-server --check dot_config/nvim --checklevel Warning`, `cd dot_config/nvim && mise run check`, targeted headless assertions for module exports, LSP commands, statusline global, buffer keymap, and format-on-save autocmd, and `chezmoi apply --dry-run --force`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Extracted the cohesive buffer, formatting, and LSP responsibilities into focused Lua modules while keeping simple and order-sensitive configuration inline. Preserved Neovim behavior and documented the full boundary assessment. Verified with Stylua, all-Lua syntax parsing, lua-language-server, mise checks, targeted headless behavior assertions, and chezmoi dry-run.
<!-- SECTION:FINAL_SUMMARY:END -->
