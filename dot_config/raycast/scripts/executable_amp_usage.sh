#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Amp Usage
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ⚡
# @raycast.packageName AmpUsage

# usage=$(bun fetch_usage "$1")
usage=$(bun fetch_amp_usage)
if [ -n "$usage" ]; then
  echo "$usage"
else
  echo "Failed to fetch"
fi
