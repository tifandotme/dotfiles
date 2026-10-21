#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Appearance
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌗

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

exec /opt/homebrew/bin/bun "$HOME/.config/theme/toggle-appearance.ts" "$@"
