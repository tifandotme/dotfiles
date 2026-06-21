---
id: TASK-004
title: use Nushell on Ubuntu box
status: To Do
assignee: []
created_date: "2026-06-20 05:25"
labels:
  - shell
  - ubuntu
  - nushell
  - next-phase
dependencies: []
priority: low
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->

## Why

Simplify cross-machine shell behavior by using Nushell on the Ubuntu VPS/box as a next phase after the XDG projects migration. macOS already uses zsh as the login bootstrap before Nushell; the box currently relies on bash login setup. Moving the box toward Nushell should reduce divergence, but it should be handled separately from the project-layout migration.

## Scope

Evaluate and implement Nushell as the interactive shell on the Ubuntu box while preserving reliable login behavior, PATH setup, Homebrew/Linuxbrew setup, XDG base/user-dir envs, and agent/tool configuration.

## Locked decisions

- This is a next-phase task, not part of TASK-003.
- Do not block the XDG projects migration on this work.
- Continue using dot_config/user-dirs.dirs as the source of truth for XDG user directory variables.
- Ensure the Ubuntu/box path still imports or exposes XDG\_\*\_DIR values when Nushell is used.

## Cold-start context

The repo is a chezmoi dotfiles repo. Root AGENTS.md says the Ubuntu VPS hostname is box and machine-specific behavior should use .chezmoi.hostname == box. Current Linux/bash setup lives in dot_bash_profile. Nushell config lives under dot_config/nushell, with scoped guidance in dot_config/nushell/AGENTS.md. TASK-003 will migrate project dirs and establish user-dirs.dirs as the source of truth imported by zsh/bash.

## Suggested approach

Investigate the safest way to launch Nushell on the box. Options include making Nushell the login shell if installed and stable, or keeping bash as login bootstrap and execing nu for interactive sessions. Prefer the least surprising approach that preserves remote SSH reliability.

## Out of scope

- Do not redo the project directory migration.
- Do not rewrite Claude/Pi/Codex/Amp sessions unless needed by this shell migration.
- Do not remove bash fallback until SSH/login recovery is clearly safe.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria

<!-- AC:BEGIN -->

- [ ] #1 Ubuntu box interactive sessions use Nushell through a documented and reliable startup path.
- [ ] #2 XDG base variables and XDG user-dir variables are available in Nushell on the box.
- [ ] #3 Existing PATH/tool setup from bash, Homebrew/Linuxbrew, mise, Bun, and local bin remains available or is intentionally migrated.
- [ ] #4 SSH/login recovery remains safe, with a fallback path documented or preserved.
<!-- AC:END -->

## Definition of Done

<!-- DOD:BEGIN -->

- [ ] #1 chezmoi apply --dry-run for the box-relevant templates completes without errors.
- [ ] #2 Relevant shell config syntax checks pass.
- [ ] #3 A final note documents whether Nushell is the login shell or launched from a bootstrap shell, and why.
<!-- DOD:END -->
