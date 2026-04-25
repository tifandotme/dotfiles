#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Caffeinate
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ☕

_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
_caffeinate_lib="$_script_dir/caffeinate_lib.sh"
[ -f "$_caffeinate_lib" ] || _caffeinate_lib="${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/caffeinate_lib.sh"
# shellcheck source=caffeinate_lib.sh
. "$_caffeinate_lib"

caffeinate_toggle

# Trigger sketchybar to update the caffeinate item
if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --trigger caffeinate_toggle
fi
