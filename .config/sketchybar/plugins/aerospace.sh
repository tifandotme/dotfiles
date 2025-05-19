#!/bin/bash

source "$CONFIG_DIR/colors.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" label.color="${FOREGROUND}" label.font="Liga SFMono Nerd Font:Bold:13.0"
else
  sketchybar --set "$NAME" label.color="${MUTED_FOREGROUND}"
fi
