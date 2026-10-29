#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Apply Theme
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎨
# @raycast.argument1 { "type": "text", "placeholder": "Optional hex color", "optional": true }

exec /opt/homebrew/bin/mise run --quiet theme:apply "$@"
