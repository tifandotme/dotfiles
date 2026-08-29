---
id: TASK-010
title: Replace WhichKey with MiniClue
status: Done
assignee:
  - '@pi'
created_date: '2026-08-17 10:11'
updated_date: '2026-08-17 10:20'
labels: []
dependencies: []
modified_files:
  - dot_config/nvim/init.lua
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the standalone WhichKey plugin with mini.clue from the already-installed mini.nvim bundle. Start with MiniClue's comprehensive documented triggers, preserve the custom buffer, files, and markdown groups, keep the t prefix, and retain safe config reloads through the existing leader-r mapping.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 which-key.nvim is no longer installed or referenced by the Neovim config
- [x] #2 MiniClue shows the comprehensive built-in clue set plus custom t, leader-f, and leader-m groups
- [x] #3 The t prefix remains available for tt, tw, tr, and to mappings
- [x] #4 Re-sourcing the Neovim init file does not duplicate MiniClue setup or fail
- [x] #5 Neovim formatting, syntax, static-analysis, smoke, and chezmoi dry-run checks pass
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Keep mini.nvim as the only source of MiniClue and remove the standalone which-key package and setup block.
2. Configure MiniClue with the documented comprehensive built-in triggers and clue generators, plus the existing t, leader-f, and leader-m custom groups.
3. Guard MiniClue setup with a global flag so the existing leader-r source command does not initialize it twice.
4. Preserve all existing keymaps and verify the t buffer mappings remain intact.
5. Run Stylua, Lua syntax, lua-language-server, headless Neovim, and chezmoi dry-run checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in dot_config/nvim/init.lua. Removed the which-key.nvim package declaration and setup, then configured mini.clue from the existing mini.nvim bundle with the documented comprehensive triggers and generators. Preserved t, leader-f, and leader-m custom groups, kept zero-delay clues, and added vim.g.mini_clue_configured to make the existing leader-r source command idempotent. Left MiniClue window placement at its default for the first visual review.

Removed the stale which-key.nvim package from the local vim.pack store after applying the updated source config. Target and source config reload smoke tests confirmed MiniClue initializes once and which-key does not return.

Validation passed: stylua --check dot_config/nvim; luac -p for all configured Lua files; lua-language-server --check dot_config/nvim --checklevel Warning; source and target Neovim headless startup; targeted MiniClue configuration assertions for 12 triggers, custom clue groups, and tt/tw/tr/to mappings; source reload assertion; grep and vim.pack checks confirming which-key is absent; chezmoi apply --dry-run --force.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced WhichKey with MiniClue from the existing mini.nvim bundle, preserved the custom prefixes and buffer mappings, added idempotent reload setup, and removed the stale WhichKey package. Verified with Lua checks, targeted Neovim assertions, reload smoke tests, package absence checks, and chezmoi dry-run.
<!-- SECTION:FINAL_SUMMARY:END -->
