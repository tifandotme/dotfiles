#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Apply Theme
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎨
# @raycast.argument1 { "type": "text", "placeholder": "Optional hex color", "optional": true }

exec bun "$HOME/.config/theme/apply-theme.ts" "$@"
