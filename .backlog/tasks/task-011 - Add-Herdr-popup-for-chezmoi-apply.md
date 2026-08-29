---
id: TASK-011
title: Add Herdr popup for chezmoi apply
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-21 18:26'
updated_date: '2026-08-21 18:43'
labels: []
dependencies: []
ordinal: 11000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide a keyboard-launched Herdr popup for interactive chezmoi apply runs, while keeping command prompts and completed output visible until the user dismisses the popup.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Cmd+Shift+C opens a Herdr popup without changing the existing Cmd+B worktree picker.
- [x] #2 The popup runs chezmoi apply interactively from the active terminal context, including any input prompts.
- [x] #3 The popup waits for any key after chezmoi apply succeeds, fails, or is cancelled.
- [x] #4 The popup uses 90% width and 90% height.
- [x] #5 The rendered configuration and Nushell configuration pass validation checks.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a reusable chezmoi-apply-popup Nushell command that runs chezmoi apply with live interactive stdin/stdout and waits for any key in a finally block after success, failure, or cancellation.
2. Add a Cmd+Shift+C Herdr popup command that invokes the Nushell helper, keeps Cmd+B unchanged, and uses the agreed 90% dimensions.
3. Validate Nushell syntax, the rendered Herdr configuration, Herdr configuration diagnostics, and the Nushell chezmoi dry-run check.
4. Manually verify normal completion, interactive prompts, failure output, cancellation, and key dismissal.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the Nushell helper and Herdr popup. Targeted chezmoi apply updated ~/.config/nushell and ~/.config/herdr, then herdr server reload-config returned status applied.
Validation passed: source loading with nu, rendered Herdr config with HERDR_CONFIG_PATH=... herdr config check, live herdr config check, targeted chezmoi apply --dry-run for both paths, git diff --check, and pseudo-terminal tests covering an interactive prompt, successful completion, failure, and Ctrl-C cancellation.
The full chezmoi apply --dry-run remains blocked by the pre-existing modified .config/pi/settings.json, which requests /dev/tty; no force or overwrite was used. Manual verification confirmed Cmd+Shift+C opens the popup and the existing Cmd+B picker remains available.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a Cmd+Shift+C Herdr popup backed by a reusable Nushell helper. The helper preserves interactive chezmoi apply input and output, then waits for a key before closing. Validated with Herdr config checks, targeted chezmoi dry-runs, pseudo-terminal behavior tests, config reload, and manual popup verification.
<!-- SECTION:FINAL_SUMMARY:END -->
