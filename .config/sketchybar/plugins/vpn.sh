#!/bin/bash

STATUS=$(/usr/local/bin/mullvad status --json)
STATE=$(echo "$STATUS" | jq -r '.state')

if [[ "$STATE" == "connected" ]]; then
  CITY=$(echo "$STATUS" | jq -r '.details.location.city')
  ICON="􀎡"
  LABEL="$CITY"
else
  ICON="􀎣"
  LABEL="Disconnected"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
