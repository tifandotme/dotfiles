#!/bin/bash

source "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
9[0-9] | 100)
  ICON="􀛨"
  ;;
[6-8][0-9])
  ICON="􀺸"
  ;;
[3-5][0-9])
  ICON="􀺶"
  ;;
[1-2][0-9])
  ICON="􀛩"
  ;;
*)
  ICON="􀛪"
  ;;
esac

if [ "$CHARGING" != "" ]; then
  ICON="􀋦"
fi

# Set color based on battery level
if [ "$PERCENTAGE" -le 10 ] && [ "$CHARGING" = "" ]; then
  ICON_COLOR="$DANGER"
  LABEL_COLOR="$DANGER"
else
  ICON_COLOR="$ACCENT"
  LABEL_COLOR="$FOREGROUND"
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.color="$ICON_COLOR" label.color="$LABEL_COLOR"
