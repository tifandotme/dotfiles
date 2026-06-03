#!/bin/bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

if [ "$SENDER" = "send_message" ]; then
  if [ -n "$MESSAGE" ] && [ -n "$HOLD" ]; then
    sketchybar --set "$NAME" \
      label="$MESSAGE" \
      drawing=on
  fi
elif [ "$SENDER" = "hide_message" ]; then
  sketchybar --set "$NAME" \
    drawing=off \
    label=""
fi
