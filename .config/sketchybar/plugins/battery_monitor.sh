#!/bin/bash

# Battery monitor script that detects battery changes and calls battery.sh
# This avoids duplicating the display logic

# Function to trigger battery.sh update
update_battery_display() {
  # Call the existing battery.sh script with proper environment
  CONFIG_DIR="$CONFIG_DIR" NAME="battery" "$CONFIG_DIR/plugins/battery.sh"

  # Debug logging (optional - uncomment to debug)
  # echo "$(date): Battery updated - $(pmset -g batt | grep -Eo '\d+%')" >> /tmp/battery_monitor.log
}

# Smart monitor that only updates when battery state changes
smart_monitor() {
  LAST_PERCENTAGE=""
  LAST_CHARGING=""

  # Initial update
  update_battery_display

  while true; do
    CURRENT_PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
    CURRENT_CHARGING="$(pmset -g batt | grep 'AC Power')"

    # Only update if percentage changed or charging status changed
    if [ "$CURRENT_PERCENTAGE" != "$LAST_PERCENTAGE" ] || [ "$CURRENT_CHARGING" != "$LAST_CHARGING" ]; then
      # Debug logging
      echo "$(date): Battery change detected: $LAST_PERCENTAGE% -> $CURRENT_PERCENTAGE%" >>/tmp/battery_monitor.log
      update_battery_display
      LAST_PERCENTAGE="$CURRENT_PERCENTAGE"
      LAST_CHARGING="$CURRENT_CHARGING"
    fi

    # Variable sleep time based on battery level
    if [ -n "$CURRENT_PERCENTAGE" ]; then
      if [ "$CURRENT_PERCENTAGE" -le 15 ] && [ "$CURRENT_CHARGING" = "" ]; then
        sleep 10 # Check every 10 seconds when critically low
      elif [ "$CURRENT_PERCENTAGE" -le 25 ] && [ "$CURRENT_CHARGING" = "" ]; then
        sleep 30 # Check every 30 seconds when low
      else
        sleep 60 # Check every minute otherwise
      fi
    else
      sleep 60 # Default if we can't read percentage
    fi
  done
}

# Handle different invocation methods
case "$1" in
"smart-monitor")
  echo "$(date): Starting battery smart monitor" >>/tmp/battery_monitor.log
  smart_monitor
  ;;
"update")
  update_battery_display
  ;;
"debug")
  echo "Debug mode - following battery changes:"
  tail -f /tmp/battery_monitor.log
  ;;
*)
  # Default behavior
  update_battery_display
  ;;
esac
