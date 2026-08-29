---
id: TASK-012
title: Manage isolated Helium app instances
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-21 18:39'
updated_date: '2026-08-21 18:53'
labels: []
dependencies: []
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create reproducible setup for Helium Work, Helium for Agents, and Helium Extra instances. Rename the agent-controlled app and update shared agent instructions without changing browser profile data.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 One setup-helium CLI creates agents, work, and extra instances through subcommands
- [x] #2 Helium for Agents uses bundle ID net.imput.helium.foragents, port 9222, and a fresh isolated data directory
- [x] #3 Helium Extra uses bundle ID net.imput.helium.extra and an isolated data directory
- [x] #4 The old setup-helium-debug and setup-helium-work commands are removed
- [x] #5 AGENTS.shared.md.tmpl names Helium for Agents and its setup command
- [x] #6 AeroSpace routes personal, work, agents, and extra instances to their intended workspaces
- [x] #7 Shell scripts pass shfmt, shellcheck, and bash -n validation
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create one setup-helium CLI with agents, work, and extra subcommands. Remove the old setup-helium-debug and setup-helium-work entrypoints with no compatibility wrappers.
2. Configure agents as ~/Applications/Helium for Agents.app with display name Helium for Agents, bundle ID net.imput.helium.foragents, fresh data directory ~/Library/Application Support/net.imput.helium.foragents, and CDP port 9222. Do not copy the old agent-browser profile.
3. Keep work as Helium Work.app with bundle ID net.imput.helium.work and its existing isolated data directory.
4. Configure extra as ~/Applications/Helium Extra.app with display name Helium Extra, bundle ID net.imput.helium.extra, fresh isolated data directory, no CDP, and routing to 0_misc for anonymous browsing.
5. Remove the old Helium Debug app bundle, update AeroSpace to use the new agents bundle ID, and add the extra rule. Leave the old unused agent data directory untouched unless explicit deletion is requested.
6. Update dot_agents/AGENTS.shared.md.tmpl to use Helium for Agents, its new app path, and setup-helium agents.
7. Apply dotfiles, recreate only app bundles, preserve the Work data directory, and validate shell scripts, plists, signatures, and AeroSpace routing.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the centralized setup-helium CLI. Created agents, work, and extra instances through the CLI twice to verify idempotent app recreation. Agents now use net.imput.helium.foragents with CDP 9222 and a fresh data directory; Work keeps net.imput.helium.work data; Extra uses net.imput.helium.extra and routes to 0_misc. Removed the old Helium Debug app bundle and old setup commands. Updated AeroSpace and AGENTS.shared.md.tmpl.

Final verification: setup-helium agents, work, and extra each succeeded twice. App metadata and deep code signatures validated. Agent CDP responded on 127.0.0.1:9222. Current AeroSpace windows showed Helium in 1_personal, Helium Work in 2_work, Helium for Agents in 3_dev, and Helium Extra in 0_misc. chezmoi apply --dry-run, tombi, git diff --check, shfmt, shellcheck, and bash -n passed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Centralized Helium instance setup in setup-helium with agents, work, and extra subcommands. Renamed the agent app and bundle ID, created isolated Extra browsing, updated AeroSpace and shared agent instructions, and removed the old setup commands. Verified idempotent recreation, app signatures, CDP, routing, and configuration checks.
<!-- SECTION:FINAL_SUMMARY:END -->
