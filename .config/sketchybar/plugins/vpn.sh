#!/bin/bash

source "$CONFIG_DIR/colors.sh"

STATUS=$(/usr/local/bin/mullvad status --json)
STATE=$(echo "$STATUS" | jq -r '.state')

if [[ "$STATE" == "connected" ]]; then
  sketchybar --set "$NAME" \
    icon="􀎡" \
    label="$(echo "$STATUS" | jq -r '.details.location.city')" \
    icon.color="${ACCENT}" \
    icon.padding_right=6
else
  sketchybar --set "$NAME" \
    icon="􀎣" \
    label="" \
    icon.color="${DANGER}" \
    icon.padding_right=0
fi
