#!/usr/bin/env bash
set -Eeuo pipefail

NAME="${NAME:-network_speed}"
STATE_FILE="${TMPDIR:-/tmp}/sketchybar_network_speed_${NAME}"

# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

is_uint() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

set_offline() {
  rm -f "$STATE_FILE"
  sketchybar --set "$NAME" \
    label="offline" \
    label.color="${WARNING}" \
    icon.drawing=off \
    label.padding_left=12
}

get_default_interface() {
  route get default 2>/dev/null | awk '/interface:/{print $2; exit}'
}

get_metered_interface() {
  local default_interface="$1"

  if [[ "$default_interface" != utun* ]]; then
    printf '%s\n' "$default_interface"
    return
  fi

  scutil --nwi 2>/dev/null | awk '
    /^Network interfaces:/ {
      for (i = 3; i <= NF; i++) {
        if ($i !~ /^(utun|lo|awdl|llw)/) {
          print $i
          exit
        }
      }
    }
  '
}

interface_is_connected() {
  local interface="$1"

  ifconfig "$interface" 2>/dev/null | awk '
    $0 ~ /flags=.*<[^>]*RUNNING[^>]*>/ { is_running = 1 }
    $1 == "inet" { has_inet = 1 }
    $1 == "status:" && $2 == "active" { is_active = 1 }
    END { exit !(has_inet && (is_active || is_running)) }
  '
}

get_interface_counters() {
  local interface="$1"

  netstat -ibn 2>/dev/null | awk -v interface="$interface" '
    $1 == interface && $3 ~ /^<Link#/ && $7 ~ /^[0-9]+$/ && $10 ~ /^[0-9]+$/ {
      print $7, $10
      exit
    }
  '
}

read_previous_state() {
  local expected_interface="$1"

  PREV_INTERFACE=""
  PREV_RX=""
  PREV_TX=""
  PREV_TIME=""

  [[ -r "$STATE_FILE" ]] || return 1
  read -r PREV_INTERFACE PREV_RX PREV_TX PREV_TIME <"$STATE_FILE" || return 1

  [[ "$PREV_INTERFACE" == "$expected_interface" ]] || return 1
  is_uint "$PREV_RX" && is_uint "$PREV_TX" && is_uint "$PREV_TIME"
}

write_state() {
  local interface="$1" rx_bytes="$2" tx_bytes="$3" timestamp="$4"
  local tmp_file

  tmp_file="$(mktemp "${STATE_FILE}.XXXXXX")"
  printf '%s %s %s %s\n' "$interface" "$rx_bytes" "$tx_bytes" "$timestamp" >"$tmp_file"
  mv "$tmp_file" "$STATE_FILE"
}

format_bits_per_second() {
  local bytes_per_second="$1"

  awk -v bps="$bytes_per_second" 'BEGIN {
    bits_per_second = bps * 8

    if (bits_per_second >= 1000000000) {
      printf "%.1fGbps", bits_per_second / 1000000000
    } else if (bits_per_second >= 1000000) {
      printf "%.0fMbps", bits_per_second / 1000000
    } else if (bits_per_second >= 1000) {
      printf "%.0fKbps", bits_per_second / 1000
    } else {
      printf "0Kbps"
    }
  }'
}

interface="$(get_metered_interface "$(get_default_interface)")"
if [[ -z "$interface" ]] || ! interface_is_connected "$interface"; then
  set_offline
  exit 0
fi

read -r current_rx current_tx <<<"$(get_interface_counters "$interface")"
if ! is_uint "${current_rx:-}" || ! is_uint "${current_tx:-}"; then
  set_offline
  exit 0
fi

current_time="$(date +%s)"
if ! read_previous_state "$interface"; then
  write_state "$interface" "$current_rx" "$current_tx" "$current_time"
  sketchybar --set "$NAME" \
    label="↓ 0Kbps ↑ 0Kbps" \
    label.color="${ACCENT}" \
    icon.drawing=off \
    label.padding_left=12
  exit 0
fi

time_diff=$((current_time - PREV_TIME))
if ((time_diff <= 0)); then
  time_diff=1
fi

rx_delta=$((current_rx - PREV_RX))
tx_delta=$((current_tx - PREV_TX))
if ((rx_delta < 0 || tx_delta < 0)); then
  rx_delta=0
  tx_delta=0
fi

rx_rate=$((rx_delta / time_diff))
tx_rate=$((tx_delta / time_diff))

download="$(format_bits_per_second "$rx_rate")"
upload="$(format_bits_per_second "$tx_rate")"
write_state "$interface" "$current_rx" "$current_tx" "$current_time"

if ((rx_rate == 0 && tx_rate == 0)); then
  label_color="${ACCENT}"
else
  label_color="${FOREGROUND}"
fi

sketchybar --set "$NAME" \
  label="↓ ${download} ↑ ${upload}" \
  label.color="$label_color" \
  icon.drawing=off \
  label.padding_left=12
