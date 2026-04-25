#!/bin/bash

# Set CONFIG_DIR with fallback if not already set
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

_caffeinate_lib="${XDG_CONFIG_HOME:-$HOME/.config}/raycast/scripts/caffeinate_lib.sh"
[ -f "$_caffeinate_lib" ] || _caffeinate_lib="$CONFIG_DIR/../raycast/scripts/caffeinate_lib.sh"
# shellcheck source=../../raycast/scripts/caffeinate_lib.sh
. "$_caffeinate_lib"

# It was not a button click
if [ -z "$BUTTON" ]; then
  sketchybar --set "$NAME" icon="$(caffeinate_icon)"
  exit 0
fi

# It is a mouse click
caffeinate_toggle
sketchybar --set "$NAME" icon="$(caffeinate_icon)"
