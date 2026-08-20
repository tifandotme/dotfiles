#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Caffeinate
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ☕

_script_dir=$(cd "$(/usr/bin/dirname "${BASH_SOURCE[0]}")" && pwd)
_caffeinate_lib="$_script_dir/caffeinate_lib.sh"
# shellcheck disable=SC1090,SC1091
. "$_caffeinate_lib"

caffeinate_toggle

# Trigger sketchybar to update the caffeinate item
if [ -x /opt/homebrew/bin/sketchybar ]; then
  /opt/homebrew/bin/sketchybar --trigger caffeinate_toggle
fi
