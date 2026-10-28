#!/bin/bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

# shellcheck disable=SC1091
. "$HOME/.config/mise/tasks/caffeinate/.lib.sh"

# It was not a button click
if [ -z "$BUTTON" ]; then
  sketchybar --set "$NAME" icon="$(caffeinate_icon)"
  exit 0
fi

# It is a mouse click
caffeinate_toggle
sketchybar --set "$NAME" icon="$(caffeinate_icon)"
