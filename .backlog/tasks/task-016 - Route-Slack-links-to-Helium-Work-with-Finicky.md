---
id: TASK-016
title: Route Slack links to Helium Work with Finicky
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-26 09:46'
updated_date: '2026-08-26 15:31'
labels: []
dependencies: []
references:
  - dot_local/bin/executable_setup-helium
  - 'https://github.com/johnste/finicky'
  - 'https://github.com/johnste/finicky/wiki/Configuration-%28v4%29'
modified_files:
  - dot_Brewfile.tmpl
  - dot_config/finicky/finicky.js
type: feature
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Route external HTTP and HTTPS links opened by the Slack desktop app to the isolated Helium Work browser while keeping Helium as the effective default for links from other applications. Manage the Finicky dependency and configuration through chezmoi on macOS.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Finicky is declared as a macOS-only Homebrew cask.
- [x] #2 The managed Finicky configuration routes opener bundle ID com.tinyspeck.slackmacgap to the configured Helium Work app path.
- [x] #3 Non-Slack HTTP and HTTPS links use /Applications/Helium.app.
- [x] #4 Slack protocol links and the existing executable_open behavior remain unchanged.
- [x] #5 The setup-helium work instance exists at the configured path before manual verification.
- [x] #6 Manual verification confirms a Slack external link opens in Helium Work and a non-Slack link opens in Helium.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add the Darwin-only Finicky Homebrew cask to dot_Brewfile.tmpl.
2. Add a chezmoi-managed ~/.config/finicky/finicky.js with JSDoc type checking, match Slack by bundle ID, send it to the setup-helium Work bundle ID net.imput.helium.work, and use /Applications/Helium.app as the default.
3. Keep dot_local/bin/executable_open and dot_local/bin/executable_setup-helium unchanged.
4. Apply the targeted dotfiles, install/start Finicky, and confirm it owns the http and https handlers.
5. Manually verify Slack and non-Slack routing, then run template, TypeScript, Brewfile, chezmoi, shell, and repository checks without adding an ADR.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented dot_Brewfile.tmpl and dot_config/finicky/finicky.js. Installed Finicky 4.2.2, applied the managed .Brewfile and custom config, and verified Finicky owns the http and https Launch Services handlers. The config uses JSDoc type checking from Finicky.d.ts and targets setup-helium Work bundle net.imput.helium.work. setup-helium work safely refused recreation because Helium Work was running; the existing app was present at the configured path. Execution tracing showed Slack -> Finicky -> Helium Work and a direct non-Slack URL -> Finicky -> personal Helium. Validation passed: TypeScript checking, Brewfile dependency check, targeted chezmoi dry-run, shellcheck, bash -n, and git diff --check. No ADR was created.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the macOS-only Finicky cask and managed ~/.config/finicky/finicky.js with JSDoc type checking. Finicky routes Slack bundle com.tinyspeck.slackmacgap to the setup-helium Work bundle net.imput.helium.work and other HTTP/HTTPS URLs to /Applications/Helium.app. Verified the custom config location, Finicky URL handlers, Slack and non-Slack routing, TypeScript checking, and repository checks. No ADR was created.
<!-- SECTION:FINAL_SUMMARY:END -->
