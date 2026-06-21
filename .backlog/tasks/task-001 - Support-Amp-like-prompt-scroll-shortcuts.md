---
id: TASK-001
title: Support Amp-like prompt scroll shortcuts
status: Done
assignee:
  - '@pi'
created_date: '2026-06-10 15:29'
updated_date: '2026-06-10 17:21'
labels: []
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add Amp-like Tab and Shift-Tab shortcuts to scroll up and down within the user prompt.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Tab and Shift-Tab behavior for user prompt scrolling is defined and implemented in Pi config or code.
- [x] #2 The shortcuts can be verified without regressing existing prompt editing behavior.
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a packaged Pi extension that wraps CustomEditor and maps Tab/Shift-Tab to prompt page scrolling only when completion should not handle the key.
2. Add package metadata, README, tsconfig, and LICENSE symlink following the existing package structure.
3. Remap app.thinking.cycle to alt+d in chezmoi Pi keybindings and remove alt+d from delete-word-forward.
4. Run repository checks and review the diff.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented @tifan/pi-prompt-scroll in /Users/tifan/personal/pi-extensions with a CustomEditor wrapper for Tab/Shift-Tab prompt page scrolling.

Autocomplete pass-through is guarded by visible autocomplete state and slash/@/# prefixes at the cursor.

Remapped app.thinking.cycle to alt+d and moved delete-word-forward to alt+delete in chezmoi Pi keybindings.

Adjusted pi-prompt-scroll to patch CustomEditor.prototype directly so /reload updates the active editor; this prevents Tab from falling through to Pi's file picker in the current session.

Corrected behavior after manual test feedback: Tab/Shift-Tab now use pi-fixed-editor navigation to jump between rendered user messages, with prompt page scroll only as a fallback.

Simplified after manual feedback: removed the separate pi-prompt-scroll package and moved Tab/Shift-Tab user-message navigation into pi-fixed-editor's input listener.

Cleanup: removed the abandoned user-message Tab/Shift-Tab navigation, removed debug logging, deleted the separate pi-prompt-scroll package, restored fixed-editor docs, and restored Tab/Shift-Tab keybinding behavior.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Cleaned up the abandoned Tab/Shift-Tab user-message navigation attempt. Removed the separate pi-prompt-scroll package, removed fixed-editor Tab handling and debug instrumentation, restored fixed-editor README/root README wording, and restored Pi keybindings so Shift-Tab/Alt-D fall back to Pi defaults. pi-fixed-editor now only keeps the editor/footer fixed and supports its existing transcript scrolling behavior.

Checks:
- bun run typecheck
- bun run lint
- bun run format:check
- python -m json.tool dot_config/pi/keybindings.json
- chezmoi apply --dry-run --force
<!-- SECTION:FINAL_SUMMARY:END -->
