#!/bin/bash

RELAY=$(/usr/local/bin/mullvad status | grep "Relay:" | awk '{print $2}')

if [[ -z "$RELAY" ]]; then
  ICON="􀎣"
  LABEL="Disconnected"
else
  ICON="􀎡"
  LABEL="$RELAY"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
