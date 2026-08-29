---
id: TASK-018
title: Allow agents to launch Helium for Agents
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-29 10:37'
updated_date: '2026-08-29 10:40'
labels: []
dependencies: []
modified_files:
  - dot_local/bin/executable_run-helium
  - dot_agents/AGENTS.shared.md.tmpl
type: enhancement
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Allow agents to recover from a failed Helium for Agents CDP connection without asking the user to open or set up the browser.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A run-helium command ensures Helium for Agents exists and launches it.
- [x] #2 The command waits until the agent CDP endpoint is ready on port 9222.
- [x] #3 Shared agent instructions tell agents to run the command and do not ask the user to start Helium or run setup-helium.
- [x] #4 The new shell script passes shfmt, shellcheck, and bash -n validation.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Keep setup-helium responsible for creating and repairing isolated app instances. 2. Add run-helium to invoke setup-helium agents, launch ~/Applications/Helium for Agents.app, and wait for CDP port 9222. 3. Update shared agent instructions to run run-helium after a failed connection and remove user-directed setup instructions. 4. Validate the shell script and rendered/template changes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented dot_local/bin/executable_run-helium. It runs setup-helium agents, opens Helium for Agents, and polls the CDP /json/version endpoint for up to 30 seconds. Updated shared instructions to call run-helium without user prompts. Validation passed: shfmt, shellcheck, bash -n, chezmoi execute-template, chezmoi apply --dry-run --force, direct run-helium launch, curl CDP readiness, and agent-browser connect 9222.

Ponytail review removed the single-use CDP_URL variable and redundant setup-helium availability check.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added run-helium so agents can autonomously create, launch, and connect to Helium for Agents. Removed user-directed recovery instructions and verified the launcher and CDP endpoint.
<!-- SECTION:FINAL_SUMMARY:END -->
