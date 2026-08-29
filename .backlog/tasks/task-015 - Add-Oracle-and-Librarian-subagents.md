---
id: TASK-015
title: Add Oracle and Librarian subagents
status: Done
assignee: []
created_date: '2026-08-25 10:05'
updated_date: '2026-08-25 10:08'
labels: []
dependencies: []
modified_files:
  - dot_config/pi/agents/oracle.md
  - dot_config/pi/agents/librarian.md
  - dot_config/pi/agents/scout.md
  - dot_config/pi/AGENTS.md.tmpl
type: enhancement
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the visible bundled Scout workflow with two focused Pi subagents. Oracle provides a human-triggered second opinion. Librarian handles external code, dependency, and technical-documentation investigation while keeping exploration out of the parent context.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Only Oracle and Librarian appear in subagent discovery
- [x] #2 Oracle uses openai-codex/gpt-5.6-sol with high thinking and is invoked only after an explicit user request
- [x] #3 Librarian uses openai-codex/gpt-5.6-luna with xhigh thinking and can be selected automatically for external technical investigation
- [x] #4 Both agents are read-only leaf agents with lineage-only sessions
- [x] #5 Rendered chezmoi configuration passes a dry run
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add Oracle and Librarian agent overrides and hide Scout.
2. Add concise parent routing instructions.
3. Format Markdown and validate agent discovery and chezmoi rendering.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added Oracle, Librarian, and hidden Scout agent definitions. Updated parent routing rules, applied the focused chezmoi targets, and verified discovery lists only Oracle and Librarian.

Validation passed: runtime discovery parsed only Librarian and Oracle with the expected model, thinking, tools, spawning, and lineage defaults; rendered routing assertions passed; focused chezmoi dry run and git diff check returned clean.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added focused Oracle and Librarian subagents, hid the bundled Scout, and added parent routing rules. Verified runtime discovery and a clean focused chezmoi dry run.
<!-- SECTION:FINAL_SUMMARY:END -->
