#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Caffeinate
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ☕

exec /opt/homebrew/bin/mise run --quiet caffeinate:toggle
