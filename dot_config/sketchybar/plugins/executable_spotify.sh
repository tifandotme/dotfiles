#!/bin/bash

set -euo pipefail

PATH="$HOME/bin:$PATH"

info="$(spotify_player get key playback)"

if [[ -n "$info" && "$info" != "null" ]]; then
  is_active="$(jq -r '.device.is_active' <<<"$info")"
  track="$(jq -r '.item.name' <<<"$info")"
  artist="$(jq -r '.item.artists | map(.name) | join(", ")' <<<"$info")"
else
  is_active=false
  track=""
  artist=""
fi

args=(
  --animate quadratic 30
  --set "$NAME"
)

if $is_active; then
  if [[ -z "$artist" && -z "$track" ]]; then
    : "No track info available..."
  elif [[ -z "$artist" ]]; then
    : "$track"
  elif [[ -z "$track" ]]; then
    : "$artist"
  else
    : "$track - $artist"
  fi
  label="$_"

  args+=(
    drawing=on
    label="$label"
  )
else
  args+=(
    drawing=off
  )
fi

sketchybar "${args[@]}"
