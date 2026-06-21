---
id: TASK-003
title: migrate projects to XDG projects layout
status: Done
assignee: []
created_date: '2026-06-20 05:12'
updated_date: '2026-06-20 05:39'
labels:
  - xdg
  - migration
  - dotfiles
dependencies: []
priority: medium
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why

Standardize the home project layout across macOS and Linux using xdg-user-dirs semantics. Follow the xdg_user crate's supported directory set, including XDG_PROJECTS_DIR as a first-class user directory. Use ~/.config/user-dirs.dirs as the source of truth for XDG user directory variables.

## Scope

Move from the old layout:

- ~/personal/*
- ~/work/*

To the new layout:

- ~/projects/personal/*
- ~/projects/work/*

Work repositories that previously lived under a Hadl grouping folder live directly under ~/projects/work, e.g. ~/work/hadl/aquasense-app becomes ~/projects/work/aquasense-app, not ~/projects/work/hadl/aquasense-app.

Update chezmoi-managed configuration and tool state that stores old project paths. Do not create compatibility symlinks or backwards-compatibility aliases.

## Locked decisions

- Follow the xdg_user-supported XDG user directory variables and set them in dot_config/user-dirs.dirs.
- Use titlecase directory names for standard user-facing XDG directories, and make only Projects lowercase: XDG_PROJECTS_DIR="$HOME/projects".
- dot_config/user-dirs.dirs is the source of truth for XDG user directory variables.
- macOS zprofile sets only XDG base directories; it does not import user-dirs.dirs.
- Nushell env.nu imports user-dirs.dirs directly so direct/login Nushell gets XDG_*_DIR values.
- bash imports user-dirs.dirs for the current Ubuntu/bash path.
- Add only XDG_PROJECTS_DIR for the project root. Do not add PROJECTS_DIR, PERSONAL_PROJECTS_DIR, or WORK_PROJECTS_DIR.
- Use ~/projects/personal and ~/projects/work. Move Hadl work repos directly to the work root, not under ~/projects/work/hadl.
- Do not create ~/personal or ~/work compatibility symlinks.
- Rewrite historical Claude Code and Pi session path references in-place, after making backups, so sessions can resume from the new paths.
- Limit historical rewrites to exact path migrations:
  - /Users/tifan/personal -> /Users/tifan/projects/personal
  - /Users/tifan/work -> /Users/tifan/projects/work
  - ~/personal -> ~/projects/personal where literal home-relative paths appear
  - ~/work -> ~/projects/work where literal home-relative paths appear
  - /Users/tifan/projects/work/hadl -> /Users/tifan/projects/work after the Hadl work-root decision

## Blast radius

Affected managed files:

- dot_config/user-dirs.dirs: set Desktop, Downloads, Templates, Public, Documents, Music, Pictures, Videos, and projects.
- dot_zprofile: keep XDG base directory setup only.
- dot_bash_profile: after setting XDG_CONFIG_HOME, import $XDG_CONFIG_HOME/user-dirs.dirs with exported variables for Linux/bash login shells.
- dot_config/nushell/env.nu: parse user-dirs.dirs and load XDG_*_DIR values directly.
- dot_config/git/config.tmpl: update includeIf paths to ~/projects/personal and ~/projects/work.
- projects/personal/dot_gitconfig and projects/work/dot_gitconfig: deploy per-directory git config to the new layout.
- dot_config/codex/private_config.toml: update trusted project paths.
- dot_config/nushell/scripts/project.nu: scan ~/projects/personal and ~/projects/work using inherited or loaded $env.XDG_PROJECTS_DIR.
- dot_config/yazi/keymap.toml: update project shortcuts.
- dot_config/pi/private_settings.json: update local pi-extension package paths to ../../projects/personal/...
- dot_config/ghostty/config: update commented shader path.
- .chezmoiignore: ensure .config/user-dirs.dirs is managed on macOS too.

Runtime state migrated with backups:

- ~/.config/claude and/or ~/.claude for Claude Code project/session metadata containing old project paths.
- ~/.config/pi and ~/.local/state/pi* for Pi session metadata containing old project paths.
- ~/.config/codex and ~/.local/state/codex if active Codex resume/trust state stores old project paths.
- ~/.config/amp or Amp state if active sessions store project paths and resume behavior depends on them.

## References

- https://docs.rs/xdg-user/latest/xdg_user/ documents support for XDG_DESKTOP_DIR, XDG_DOCUMENTS_DIR, XDG_DOWNLOAD_DIR, XDG_MUSIC_DIR, XDG_PICTURES_DIR, XDG_PROJECTS_DIR, XDG_PUBLICSHARE_DIR, XDG_TEMPLATES_DIR, and XDG_VIDEOS_DIR.

## Out of scope / follow-ups

- Do not introduce generic PROJECTS_DIR-style convenience variables.
- Do not create compatibility symlinks.
- Do not migrate the Ubuntu box to Nushell in this phase; that is TASK-004.
- Do not redesign unrelated agent config or session storage.
- Do not rewrite arbitrary historical logs unless they affect resume or contain exact old project paths under the migration map.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Repositories are organized under ~/projects/personal and ~/projects/work, Hadl work repos live directly under ~/projects/work, and no ~/personal or ~/work compatibility symlinks are created.
- [x] #2 Managed configs no longer reference old ~/personal or ~/work project locations, except in explicit backup files or migration notes.
- [x] #3 Git personal/work identity includes resolve for repositories under ~/projects/personal and ~/projects/work.
- [x] #4 Claude Code and Pi session/config state containing exact old project paths is backed up and rewritten so resume targets the new paths.
- [x] #5 Codex, Amp, or other agent path state is migrated if inspection shows it is needed for trust or resume behavior.
- [x] #6 dot_config/user-dirs.dirs is the source of truth for XDG user dirs, Nushell imports it directly, bash imports it for the current Ubuntu/bash path, and XDG_PROJECTS_DIR="$HOME/projects" is exposed with only Projects lowercase.
<!-- AC:END -->





## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Inspect runtime directories for Claude Code, Pi, Codex, and Amp session/config files containing old project paths. Record exact files before modifying anything.
2. Back up every runtime state file that will be rewritten, preserving paths and timestamps where practical.
3. Update dot_config/user-dirs.dirs as the source of truth following xdg_user's supported set: Desktop, Downloads, Templates, Public, Documents, Music, Pictures, Videos, and XDG_PROJECTS_DIR="$HOME/projects" as the only lowercase user dir.
4. Keep dot_zprofile limited to XDG base directory setup. Update dot_bash_profile to import $XDG_CONFIG_HOME/user-dirs.dirs for Linux/bash. Update dot_config/nushell/env.nu to parse user-dirs.dirs directly for direct/login Nushell.
5. Update managed project-path consumers: Git includeIf rules, Codex trusted projects, Nushell project picker, Yazi shortcuts, Pi extension package paths, and Ghostty commented shader path.
6. Move per-directory git identity files into projects/personal and projects/work so ~/projects/personal/.gitconfig and ~/projects/work/.gitconfig are available after chezmoi apply.
7. Move existing repositories from ~/personal and ~/work into ~/projects/personal and ~/projects/work. Move Hadl work repos directly to ~/projects/work rather than ~/projects/work/hadl. Do not leave compatibility symlinks.
8. Rewrite exact old path references in backed-up Claude Code and Pi session/config state so resume targets the new paths. Include Codex/Amp only if inspection shows resume-critical path state.
9. Run focused verification: chezmoi execute-template for edited templates, shellcheck/bash -n for edited shell scripts, Nushell parse/login env checks, chezmoi apply --dry-run, git config includeIf inspection, managed-config grep, and a smoke check that project picker and agent resume metadata reference new paths.
10. Document backup locations and final design in implementation notes.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented migration with user redirect applied: Hadl work repos now live directly under ~/projects/work rather than ~/projects/work/hadl.

Runtime session backups:
- /Users/tifan/.local/state/migrations/project-paths/20260620-122848 backed up 826 matching Claude/Pi/Codex/Amp state files before rewriting old ~/personal and ~/work paths; 814 files rewritten; 35 encoded session/project directories renamed.
- /Users/tifan/.local/state/migrations/project-paths/20260620-122948 backed up 620 matching runtime files before flattening /Users/tifan/projects/work/hadl to /Users/tifan/projects/work; 608 files rewritten; 17 encoded session/project directories renamed.

Applied targeted chezmoi targets for user-dirs, zprofile, git config, codex config, nushell project picker, yazi keymap, pi settings, ghostty config, project gitconfigs, and work mise.toml. Full plain chezmoi apply --dry-run initially blocked on unrelated changed target ~/.local/state/skills/.skill-lock.json needing TTY; full chezmoi apply --dry-run --force is clean after targeted apply.

Follow-up fix: direct non-login Nushell did not load XDG user-dir variables because it did not inherit zsh's imported user-dirs.dirs. Added a Nushell env.nu fallback parser that reads /Users/tifan/.config/user-dirs.dirs and load-envs XDG_*_DIR values. Verified with nu -l -c that XDG_PROJECTS_DIR and other user-dir vars are present.

Correction after final review: dot_zprofile no longer imports user-dirs.dirs. Final design is: zprofile sets only XDG base dirs; Nushell env.nu imports user-dirs.dirs directly for macOS/direct Nushell; dot_bash_profile still imports user-dirs.dirs for the current Ubuntu/bash path.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Migrated project layout to ~/projects/personal and ~/projects/work, with Hadl work repos flattened into the work root. Updated XDG user dirs, Nushell direct import of user-dirs.dirs, bash import for Ubuntu/bash, Git includes, Codex trust paths, Nushell project picker, Yazi shortcuts, Pi extension paths, Ghostty commented shader path, and chezmoi source deployment for project gitconfigs/mise. zprofile now only sets XDG base dirs. Backed up and rewrote Claude/Pi session/config path state for resume. Verified shell syntax, Nushell parse/login env, git template render, targeted chezmoi apply, full dry-run with --force, Git includes, and managed-config grep.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 chezmoi apply --dry-run completes with expected changes and no template errors.
- [x] #2 Relevant templates render with chezmoi execute-template where applicable.
- [x] #3 Edited shell scripts, if any, pass shellcheck and bash -n according to repo guidance.
- [x] #4 A final grep/search shows no unintended managed-config references to /Users/tifan/personal, /Users/tifan/work, ~/personal, or ~/work.
- [x] #5 Backups of rewritten runtime session/config files exist and are documented in implementation notes.
<!-- DOD:END -->
