#!/bin/bash

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

if [[ "$SENDER" == "send_message" ]]; then
  if [[ -n "${MESSAGE:-}" && -n "${HOLD:-}" ]]; then
    sketchybar --set "$NAME" \
      label="$MESSAGE" \
      drawing=on

    if [[ "$HOLD" != "true" ]]; then
      sleep 1
      sketchybar --set "$NAME" \
        drawing=off \
        label=""
    fi
  fi
elif [[ "$SENDER" == "hide_message" ]]; then
  sketchybar --set "$NAME" \
    drawing=off \
    label=""
fi
