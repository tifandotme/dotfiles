#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Apply Theme
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎨
# @raycast.argument1 { "type": "text", "placeholder": "Optional hex color", "optional": true }

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

exec /opt/homebrew/bin/bun "$HOME/.config/theme/apply-theme.ts" "$@"
