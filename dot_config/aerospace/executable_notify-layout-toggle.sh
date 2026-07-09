#!/usr/bin/env bash
set -euo pipefail

layout="$(aerospace list-windows --focused --format '%{window-layout}')"

if [[ "$layout" == "floating" ]]; then
  message="[FLOATING]"
else
  message="[TILING]"
fi

sketchybar --trigger send_message MESSAGE="$message" HOLD="false"
