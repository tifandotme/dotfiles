---
id: TASK-019
title: Add minimal Pi footer and fixed editor border
status: Done
assignee:
  - '@tifan'
created_date: '2026-08-29 14:02'
updated_date: '2026-08-29 14:28'
labels: []
dependencies: []
modified_files:
  - .chezmoiignore
  - dot_config/pi/extensions/pi-minimal-ui.ts
  - dot_config/pi/extensions/tsconfig.json
  - dot_config/pi/private_settings.json
priority: low
type: feature
ordinal: 19000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Why

Keep Pi visually minimal without losing the useful native footer information or the editor workflow.

## Scope

Add a local Pi UI extension to control the extension-status row and keep editor borders visually stable. Update the managed Pi settings to load it.

## Locked decisions

- Hide only the third extension-status row. Keep Pi’s native path, usage, context, and model rows.
- Hide all extension statuses, not only the current MCP and ponytail entries.
- The extension-status row is hidden by default for each session.
- `/toggle-extension-status` toggles the row for the current session only.
- Showing the row again restores Pi’s built-in footer.
- Use the active theme’s `thinkingMinimal` color for normal editor borders at every thinking level.
- Keep Pi’s separate bash-mode border color.
- Keep this as a local dotfiles extension, not a new reusable package.

## Cold-start context

Pi 0.84.4 has no settings key for hiding extension statuses. `ctx.ui.setFooter()` replaces the complete built-in footer, while its `footerData` exposes extension statuses. Pi’s native editor maps thinking levels to theme tokens such as `thinkingMinimal`, `thinkingLow`, and `thinkingMax`.

The managed settings file is `dot_config/pi/private_settings.json`. The local extension should live below `dot_config/pi/extensions/`.

## Out of scope / follow-ups

- Do not disable or clear statuses owned by MCP, ponytail, or other extensions.
- Do not persist the toggle across restarts.
- Do not change Pi core or add a published package.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Pi starts with the extension-status row hidden while the native footer rows remain visible.
- [x] #2 `/toggle-extension-status` shows and hides the complete extension-status row.
- [x] #3 The toggle hides all current and future extension status entries without stopping their extensions.
- [x] #4 Normal editor borders use the active theme’s `thinkingMinimal` color at every thinking level.
- [x] #5 Bash-mode editor borders retain the existing bash-mode color.
- [x] #6 Pi remains usable in non-TUI modes without UI errors.
- [x] #7 Chezmoi template rendering and dry-run application complete without errors.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add `dot_config/pi/extensions/pi-minimal-ui.ts` as a TUI-safe local extension.
2. Reuse Pi’s public `FooterComponent` with a footer-data adapter that removes extension statuses while retaining the native two-row footer; restore the built-in footer when toggled.
3. Wrap Pi’s `CustomEditor` so normal borders use the active theme’s minimal thinking color, while bash mode keeps its native color.
4. Register `/toggle-extension-status` and load the extension from `dot_config/pi/private_settings.json`.
5. Add a source-only `dot_config/pi/extensions/tsconfig.json`; ignore its rendered target in `.chezmoiignore`.
6. Run TypeScript, lint, runtime smoke, TUI smoke, and chezmoi validation.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the local extension and source-only TypeScript config. Verified TypeScript, Oxfmt, Oxlint, Pi JSON/RPC startup, Pi TUI startup, custom two-row footer output, fixed minimal border ANSI output, rendered settings JSON, ignored tsconfig target, and chezmoi dry-run.

Validation evidence:
- `tsc -p dot_config/pi/extensions/tsconfig.json` passed.
- Oxfmt check and Oxlint passed.
- Pi JSON mode exited 0 with no stderr.
- Pi RPC command discovery included `/toggle-extension-status` with no stderr.
- TUI smoke rendered the native two-row footer with a synthetic `TEST_STATUS` hidden, and the footer renderer rejected extension-status access.
- TUI smoke rendered xhigh using the minimal border color and a bash-mode probe using the bash color.
- `chezmoi execute-template` produced valid JSON and `chezmoi apply --dry-run --force --no-tty` completed successfully.
- `chezmoi managed` included `pi-minimal-ui.ts` and excluded `tsconfig.json`.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added a local Pi UI extension that hides the extension-status row by default, toggles it with `/toggle-extension-status`, restores Pi’s built-in footer, and fixes normal editor borders to the active theme’s minimal thinking color while preserving bash mode. Added source-only TypeScript checking and ignored its rendered target. Verified with TypeScript, formatting, lint, Pi JSON/RPC/TUI smoke tests, and chezmoi validation.
<!-- SECTION:FINAL_SUMMARY:END -->
