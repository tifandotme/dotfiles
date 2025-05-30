#!/bin/bash

source "$CONFIG_DIR/colors.sh"

SSID=$(system_profiler SPAirPortDataType | awk '/Current Network Information:/ { getline; print substr($0, 13, (length($0) - 13)); exit }')

if [ "$SSID" = "" ]; then
  sketchybar --set "$NAME" \
    icon="􀙈" \
    label="" \
    icon.color="${DANGER}" \
    icon.padding_right=0
else
  sketchybar --set "$NAME" \
    icon="􀙇" \
    label="$SSID" \
    icon.color="${ACCENT}" \
    icon.padding_right=6
fi
