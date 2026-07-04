---
id: TASK-006
title: Finish Rift migration and remove AeroSpace
status: To Do
assignee: []
created_date: '2026-07-04 10:56'
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
- [ ] #1 Rift starts at login via its service and AeroSpace does not start at login
- [ ] #2 AeroSpace is removed from the Brewfile and uninstalled after confirming no other package depends on the tap
- [ ] #3 SketchyBar workspace items and highlighting work using Rift only, with AeroSpace fallback code removed
- [ ] #4 Any reused scripts, such as the wifi toggle, are moved out of the AeroSpace config path before deleting AeroSpace files
- [ ] #5 chezmoi dry-run for the affected config paths completes without errors
<!-- AC:END -->
