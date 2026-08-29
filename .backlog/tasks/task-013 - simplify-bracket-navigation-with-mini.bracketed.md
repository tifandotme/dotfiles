---
id: TASK-013
title: simplify bracket navigation with mini.bracketed
status: Done
assignee: []
created_date: '2026-08-22 16:07'
updated_date: '2026-08-23 14:17'
labels: []
dependencies: []
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Adopt mini.bracketed for Neovim bracketed navigation and evaluate mini.diff as the in-editor Git diff provider, while preserving the Helix-style gh line-start mapping.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 MiniBracketed provides the agreed default bracketed navigation targets without overwriting gh.
- [x] #2 MiniDiff provides in-editor hunk visualization, navigation, and MiniMap diff integration.
- [x] #3 Git staging and unstaging remain available through LazyGit.
- [x] #4 The existing gh line-start mapping remains unchanged.
- [x] #5 No new third-party dependency is added, and Gitsigns remains easy to restore during evaluation.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Remove the Gitsigns package spec, setup block, and MiniMap Gitsigns integration.
2. Configure mini.diff with sign-column visualization, default hunk navigation, safe leader mappings for staging/resetting hunks, and a leader mapping for the overlay while preserving gh as line start.
3. Enable all mini.bracketed defaults, remove duplicate diagnostic mappings, and preserve u/U undo behavior while registering U redo states.
4. Remove the local Gitsigns package from the vim.pack directory.
5. Run formatting, Lua analysis, syntax, Neovim smoke, MiniDiff mapping, and chezmoi checks.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
MiniDiff is now the in-editor Git diff provider. It uses sign-column visualization, default [h]/]h and [H]/]H hunk navigation, leader mappings for staging/resetting current or selected hunks, and <leader>do for the whole-buffer overlay. MiniBracketed uses all defaults; the custom diagnostic mappings were removed. gh remains the Helix-style line-start mapping, and U explicitly registers redo states. Gitsigns was removed from the vim.pack spec and local package directory.

Validation passed: stylua --check, lua-language-server, luac, Neovim smoke test, MiniDiff buffer hunk detection, MiniMap integration count, and chezmoi dry-run.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced Gitsigns with MiniDiff and enabled all MiniBracketed defaults. Preserved gh as line start, kept u/U undo behavior, added simple hunk and overlay actions, and verified the active configuration with Neovim and chezmoi checks.
<!-- SECTION:FINAL_SUMMARY:END -->
