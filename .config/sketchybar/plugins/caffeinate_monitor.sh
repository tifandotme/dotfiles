#!/bin/bash

# Caffeinate monitor script that automatically kills caffeinate when display turns off
# This prevents caffeinate from keeping the system awake when screen is locked/off due to inactivity

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

# Function to check if display is on (1) or off (0)
is_display_on() {
  ioreg -n IODisplayWrangler -r | grep DevicePowerState | awk '{print $3}' | tr -d '\n'
}

# Function to get caffeinate PID
get_caffeinate_pid() {
  pgrep -f "caffeinate -id" | head -1
}

# Function to kill caffeinate and update Sketchybar
kill_caffeinate_if_running() {
  CAFFINATE_PID=$(get_caffeinate_pid)
  if [ -n "$CAFFINATE_PID" ]; then
    kill "$CAFFINATE_PID" 2>/dev/null
    # Update Sketchybar icon (clear it to indicate off)
    sketchybar --set caffeinate icon="" 2>/dev/null
    echo "$(date): Caffeinate killed due to display off" >>/tmp/caffeinate_monitor.log
  fi
}

# Smart monitor that only acts when display state changes
smart_monitor() {
  LAST_DISPLAY_STATE=""

  while true; do
    CURRENT_DISPLAY_STATE=$(is_display_on)

    # Only act if display state changed to off
    if [ "$CURRENT_DISPLAY_STATE" = "0" ] && [ "$LAST_DISPLAY_STATE" != "0" ]; then
      kill_caffeinate_if_running
    fi

    LAST_DISPLAY_STATE="$CURRENT_DISPLAY_STATE"

    # Variable sleep: faster when display is off (to react quickly), slower when on
    if [ "$CURRENT_DISPLAY_STATE" = "0" ]; then
      sleep 5 # Check every 5 seconds when display is off
    else
      sleep 30 # Check every 30 seconds when display is on
    fi
  done
}

# Handle different invocation methods
case "$1" in
"smart-monitor")
  echo "$(date): Starting caffeinate smart monitor" >>/tmp/caffeinate_monitor.log
  smart_monitor
  ;;
"check")
  # Manual check (for testing)
  if [ "$(is_display_on)" = "0" ]; then
    kill_caffeinate_if_running
  fi
  ;;
"debug")
  echo "Debug mode - following caffeinate monitor:"
  tail -f /tmp/caffeinate_monitor.log
  ;;
*)
  # Default: just check once
  if [ "$(is_display_on)" = "0" ]; then
    kill_caffeinate_if_running
  fi
  ;;
esac
