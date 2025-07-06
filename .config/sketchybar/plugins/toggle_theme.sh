#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle System Appearance
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌗

# Path to your git config symlink
SYMLINK="$HOME/.config/git/config"

# Resolve to real file (handles relative symlinks)
TARGET=$(readlink "$SYMLINK")
if [[ -z "$TARGET" ]]; then
  CONFIG_FILE="$SYMLINK"
elif [[ "$TARGET" = /* ]]; then
  CONFIG_FILE="$TARGET"
else
  CONFIG_FILE="$(cd "$(dirname "$SYMLINK")" && pwd)/$TARGET"
fi

# Toggle macOS appearance
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'

# Determine new value for delta light
if osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode' | grep -q "true"; then
  NEW_VAL="false"
else
  NEW_VAL="true"
fi

# If [delta] section exists, update or insert light line
if grep -q '^\[delta\]' "$CONFIG_FILE"; then
  awk -v newval="$NEW_VAL" '
        BEGIN { in_delta=0; done=0 }
        /^\[delta\]/ { print; in_delta=1; next }
        in_delta && /^[[:space:]]*light[[:space:]]*=/ {
            if (!done) { print "    light = " newval; done=1 }
            next
        }
        in_delta && /^\[/ { if (!done) { print "    light = " newval; done=1 }; in_delta=0 }
        { print }
        END { if (in_delta && !done) print "    light = " newval }
    ' "$CONFIG_FILE" >"$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
else
  # If [delta] section missing, add it at the end
  printf "\n[delta]\n    light = %s\n" "$NEW_VAL" >>"$CONFIG_FILE"
fi
