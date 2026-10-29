#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Wired In
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌊

exec /opt/homebrew/bin/mise run --quiet accessibility:toggle-wired-in
