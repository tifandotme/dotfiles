#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Network traffic calculation
STATS_FILE="/tmp/sketchybar_network_stats_$NAME"
INTERFACE=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
CURRENT_RX=$(netstat -ib 2>/dev/null | grep "^$INTERFACE" | head -1 | awk '{print $7}')
CURRENT_TX=$(netstat -ib 2>/dev/null | grep "^$INTERFACE" | head -1 | awk '{print $10}')

if [ -f "$STATS_FILE" ]; then
  PREV_RX=$(head -1 "$STATS_FILE")
  PREV_TX=$(tail -1 "$STATS_FILE")
  PREV_TIME=$(stat -f %m "$STATS_FILE" 2>/dev/null || date -r "$STATS_FILE" +%s)
else
  PREV_RX=$CURRENT_RX
  PREV_TX=$CURRENT_TX
  PREV_TIME=$(date +%s)
fi

CURRENT_TIME=$(date +%s)
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
if [ $TIME_DIFF -le 0 ]; then
  TIME_DIFF=1
fi

RX_RATE=$(((CURRENT_RX - PREV_RX) / TIME_DIFF * 8))
TX_RATE=$(((CURRENT_TX - PREV_TX) / TIME_DIFF * 8))
if [ $RX_RATE -lt 0 ]; then RX_RATE=0; fi
if [ $TX_RATE -lt 0 ]; then TX_RATE=0; fi

format_speed() {
  local speed=$1
  if [ $speed -ge 1000000 ]; then
    echo "$((speed / 1000000))M"
  elif [ $speed -ge 1000 ]; then
    echo "$((speed / 1000))K"
  else
    echo "0K"
  fi
}

DOWNLOAD=$(format_speed $RX_RATE)
UPLOAD=$(format_speed $TX_RATE)
echo "$CURRENT_RX" >"$STATS_FILE"
echo "$CURRENT_TX" >>"$STATS_FILE"

# Check if we have network connectivity
if [ -z "$INTERFACE" ] || [ -z "$CURRENT_RX" ] || [ -z "$CURRENT_TX" ] || ! ifconfig "$INTERFACE" 2>/dev/null | grep -q "inet "; then
  sketchybar --set "$NAME" label="No connection"
else
  sketchybar --set "$NAME" label="↓${DOWNLOAD} ↑${UPLOAD}"
fi
