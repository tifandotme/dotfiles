#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Undo Wallpaper Theme
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ↩️

exec bun "$HOME/.config/theme/apply-theme.ts" --undo
