#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Chezmoi Apply
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🏠

if chezmoi apply; then
  echo "Chezmoi applied successfully"
else
  echo "Chezmoi apply failed"
  exit 1
fi
