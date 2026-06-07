#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Appearance
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌗

exec bun "$HOME/.config/theme/toggle-appearance.ts" "$@"
