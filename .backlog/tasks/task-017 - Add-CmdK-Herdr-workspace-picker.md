---
id: TASK-017
title: Add Cmd+K Herdr workspace picker
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-27 18:07'
updated_date: '2026-08-27 18:13'
labels: []
dependencies: []
references:
  - 'https://herdr.dev/docs/configuration/'
  - 'https://herdr.dev/docs/cli-reference/'
  - 'https://github.com/junegunn/fzf/blob/master/README.md'
modified_files:
  - dot_config/herdr/config.toml.tmpl
  - dot_config/nushell/scripts/project.nu
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a Herdr command-centre popup that opens with Cmd+K, filters currently open Herdr workspaces by name with fzf, and focuses the selected workspace on Enter.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Cmd+K opens an 80% by 80% Herdr popup without changing the layout.
- [x] #2 The picker lists all currently open Herdr workspaces and filters them by workspace label.
- [x] #3 Pressing Enter focuses the selected workspace using its stable workspace ID.
- [x] #4 Pressing Escape or cancelling closes the popup without changing the focused workspace.
- [x] #5 Empty workspace lists and Herdr command failures produce a clear result without a Nushell error.
- [x] #6 Rendered Herdr and Nushell configuration pass validation checks.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add an 80% by 80% cmd+k Herdr popup that sources the existing Nushell modules and runs a workspace picker. 2. Add a minimal Nushell picker that reads herdr workspace list, displays workspace labels through fzf, preserves workspace IDs in hidden fields, and focuses the selected workspace. 3. Handle empty lists, command failures, and fzf cancellation without changing focus. 4. Validate Nushell syntax, rendered Herdr configuration, Herdr diagnostics, and scripted picker behavior.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in dot_config/herdr/config.toml.tmpl and dot_config/nushell/scripts/project.nu. The cmd+k popup uses an 80% by 80% Herdr popup, reads workspace list JSON, filters labels with fzf, disambiguates duplicate labels with checkout-path suffixes, and focuses the selected workspace ID. Validation passed: nufmt --dry-run, nu --ide-check 100, rendered herdr config check, live herdr config check, targeted chezmoi apply --dry-run, and git diff --check for both changed files. Scripted checks covered selecting a workspace, duplicate-label display, cancellation without focus, empty lists, list failures, and the live workspace list with cancellation. Targeted chezmoi apply and herdr server reload-config both succeeded.

Applied ponytail review cleanup: removed the unnecessary --env flag and unused enumerate/label fields. Re-applied the Nushell source and re-ran formatting, diagnostics, rendered Herdr config, and diff checks.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the Cmd+K Herdr workspace command-centre popup. It lists open workspaces by label with fzf, preserves workspace IDs, focuses the selected workspace, handles cancellation and command failures, and disambiguates duplicate labels. Verified with scripted picker flows, Nushell formatting and diagnostics, rendered and live Herdr config checks, targeted chezmoi dry-run, targeted apply, config reload, and diff checks.
<!-- SECTION:FINAL_SUMMARY:END -->
