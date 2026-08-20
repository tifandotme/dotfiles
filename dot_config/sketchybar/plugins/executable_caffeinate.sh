#!/bin/bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

_caffeinate_lib="$CONFIG_DIR/../raycast/scripts/caffeinate_lib.sh"
# shellcheck source=../../raycast/scripts/caffeinate_lib.sh
# shellcheck disable=SC1091
. "$_caffeinate_lib"

# It was not a button click
if [ -z "$BUTTON" ]; then
  sketchybar --set "$NAME" icon="$(caffeinate_icon)"
  exit 0
fi

# It is a mouse click
caffeinate_toggle
sketchybar --set "$NAME" icon="$(caffeinate_icon)"
