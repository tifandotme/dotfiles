---
id: TASK-006
title: Finish Rift migration and remove AeroSpace
status: Done
assignee:
  - '@tifan'
created_date: '2026-07-04 10:56'
updated_date: '2026-07-04 16:54'
labels:
  - rift
  - cleanup
dependencies: []
priority: low
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After validating Rift as the daily window manager, remove AeroSpace startup, package, config, and SketchyBar fallback code without breaking workspace highlighting or login startup.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Rift starts at login via its service and AeroSpace does not start at login
- [x] #2 AeroSpace is removed from the Brewfile and uninstalled after confirming no other package depends on the tap
- [x] #3 SketchyBar workspace items and highlighting work using Rift only, with AeroSpace fallback code removed
- [x] #4 Any reused scripts, such as the wifi toggle, are moved out of the AeroSpace config path before deleting AeroSpace files
- [x] #5 chezmoi dry-run for the affected config paths completes without errors
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect current Rift, AeroSpace, Brewfile, keymap, and SketchyBar config paths.
2. Move reused wifi toggle script out of the AeroSpace path and update Rift startup references.
3. Remove AeroSpace package/startup/config/fallback code while keeping Rift workspace highlighting.
4. Run shell syntax checks and chezmoi dry-run for affected paths, then update task status and criteria.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented Rift-only migration: removed AeroSpace Brewfile/tap trust entries, deleted AeroSpace config/scripts/plugins, moved the wifi reconnect AppleScript under ~/.config/rift, and simplified SketchyBar workspace registration to Rift only.

Runtime cleanup: nikitabobko/tap/aerospace was uninstalled, nikitabobko/tap was untapped, and Rift was started via 'rift service start' (not Homebrew services).

Validation: rg found no AeroSpace/nikitabobko references in managed config; shellcheck and bash -n passed for touched SketchyBar scripts; JSON/TOML parse checks passed; chezmoi apply --dry-run --force passed for AeroSpace, Rift, SketchyBar, keymaps, Homebrew trust, and Brewfile targets. brew bundle check still reports existing install/update/trust issues outside this task.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Finished Rift migration and removed AeroSpace from managed config and the local Homebrew install. Rift is started via rift service, SketchyBar now uses only Rift workspace data, the wifi reconnect AppleScript lives under the Rift config path, and affected chezmoi dry-runs pass. Remaining Brew bundle check failures are unrelated install/update/trust drift.
<!-- SECTION:FINAL_SUMMARY:END -->
