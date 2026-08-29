---
id: TASK-014
title: Add Herdr project-popup session resume picker
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-23 02:14'
updated_date: '2026-08-23 02:49'
labels: []
dependencies: []
documentation:
  - /herdrdev/herdr
modified_files:
  - dot_config/nushell/scripts/project.nu
priority: medium
type: feature
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the existing Herdr project/worktree popup so users can select a saved Pi or Claude session and resume it in the correct Herdr workspace. Reuse an already-running matching session, otherwise create or open the workspace and start the session in a new tab. The interaction uses a second selectable FZF session picker because popup preview output cannot execute links.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The project popup offers a resume action that opens a selectable session list for the selected root project or worktree.
- [x] #2 Selecting an already-running Pi or Claude session focuses its existing Herdr agent instead of starting a duplicate.
- [x] #3 Selecting a session in an open workspace creates and focuses a new tab with the correct Pi or Claude resume command.
- [x] #4 Selecting a session in a closed root project or worktree creates or opens the required workspace before starting the session.
- [x] #5 Cancelling the session picker returns to the project picker without changing Herdr layout.
- [x] #6 Pi and Claude session rows retain their current title, activity time, and branch information.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Preserve session paths and IDs while discovering Pi and Claude sessions. 2. Add a Ctrl-R session picker to the existing project popup. 3. Resolve existing or missing root/worktree workspaces and focus matching running agents. 4. Create a tab and start Pi or Claude through Herdr agent start, relying on the Nushell Claude wrapper for existing flags. 5. Validate Nushell syntax, rendered config, and the session/workspace flow.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the shared session inventory, preview resume hint, two-stage Ctrl-R FZF session picker, duplicate-session focus, workspace lookup/create/open, tab creation, and Herdr agent start flow in dot_config/nushell/scripts/project.nu.

Validation passed: nufmt reported the file already formatted; nu --ide-check returned 0; source and inventory checks passed; the FZF session picker was scripted with a real session selection and cancellation; fake Herdr integration tests verified focus-existing, open-workspace tab creation, closed-root workspace creation, and closed-worktree opening; __preview-sessions printed the Ctrl-R hint and existing session metadata; chezmoi apply --dry-run ~/.config/nushell/ completed without output; rendered Herdr config passed herdr config check; git diff --check returned 0.

Post-completion bug fix: session inventory ran under the core.nu ls alias (eza), so the Ctrl-R picker saw zero sessions. Added a builtin-compatible file-info helper and captured outer FZF completion output so expected-key and cancellation statuses do not hit the broad error handler.

Regression evidence: with a fake FZF returning Ctrl-R with exit 130, the real open-project parser continued into the session picker; the picker saw 20 sessions under both plain and core.nu-loaded environments. A scripted flow then issued agent list, worktree list, tab create, and agent start with the selected Claude resume ID. A real PTY smoke run of open-project backoffice-windmill with Ctrl-R and cancellation produced no error output.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented and fixed the project-popup Ctrl-R session picker in dot_config/nushell/scripts/project.nu. The picker now works when project.nu is sourced after core.nu by bypassing the ls/eza alias, and it handles FZF completion statuses without closing on Ctrl-R. It preserves Pi paths and Claude IDs, focuses matching agents, reuses or creates workspaces, creates tabs, and starts the correct resume command. Verified with Nushell checks, plain/core session inventory checks, scripted FZF and Herdr command-flow regression tests, PTY smoke testing, chezmoi dry-run, Herdr config validation, and git diff --check.
<!-- SECTION:FINAL_SUMMARY:END -->
