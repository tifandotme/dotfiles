#!/bin/bash
# Reads Spotify OAuth token from ~/.cache/sketchybar/spotify_token.json.
# Token is chezmoi-managed at dot_cache/sketchybar/encrypted_private_spotify_token.json.age.

set -euo pipefail

# shellcheck disable=SC1091
# shellcheck source=/Users/tifan/.local/share/chezmoi/dot_config/theme/palette.sh
# shellcheck disable=SC1091
source "$HOME/.config/theme/palette.sh"

PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
TOKEN_FILE="$HOME/.cache/sketchybar/spotify_token.json"
CLIENT_ID="d420a117a32841c2b3474932e49fb54b"

sync_token_to_chezmoi() {
  if command -v chezmoi >/dev/null; then
    chezmoi add --encrypt "$TOKEN_FILE" >/dev/null 2>&1 || true
  fi
}

if [[ ! -f "$TOKEN_FILE" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

access_token="$(jq -r '.access_token // empty' "$TOKEN_FILE")"
refresh_token="$(jq -r '.refresh_token // empty' "$TOKEN_FILE")"
expires_at="$(jq -r '.expires_at // empty' "$TOKEN_FILE")"

if [[ -z "$access_token" || -z "$refresh_token" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

expires_at_epoch=0
if [[ -n "$expires_at" ]]; then
  expires_at_without_fraction="${expires_at%%.*}Z"
  expires_at_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$expires_at_without_fraction" +%s 2>/dev/null || echo 0)"
fi

if [[ "$expires_at_epoch" -le "$(date -u +%s)" ]]; then
  refresh_response="$(curl --silent --fail --request POST "https://accounts.spotify.com/api/token" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "refresh_token=$refresh_token" \
    --data-urlencode "client_id=$CLIENT_ID" 2>/dev/null)" || {
    sketchybar --set "$NAME" drawing=off
    exit 0
  }

  access_token="$(jq -r '.access_token // empty' <<<"$refresh_response")"
  new_refresh_token="$(jq -r '.refresh_token // empty' <<<"$refresh_response")"
  expires_in="$(jq -r '.expires_in // 3600' <<<"$refresh_response")"

  if [[ -z "$access_token" ]]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
  fi

  if [[ -z "$new_refresh_token" ]]; then
    new_refresh_token="$refresh_token"
  fi

  tmp_token_file="$(mktemp)"
  jq \
    --arg access_token "$access_token" \
    --arg refresh_token "$new_refresh_token" \
    --arg expires_at "$(date -u -v+"${expires_in}"S +%Y-%m-%dT%H:%M:%S.000000Z)" \
    '.access_token = $access_token | .refresh_token = $refresh_token | .expires_at = $expires_at' \
    "$TOKEN_FILE" >"$tmp_token_file"
  mv "$tmp_token_file" "$TOKEN_FILE"
  sync_token_to_chezmoi
fi

status_file="$(mktemp)"
http_status="$(curl --silent --output "$status_file" --write-out '%{http_code}' \
  --header "Authorization: Bearer $access_token" \
  "https://api.spotify.com/v1/me/player/currently-playing?additional_types=track,episode")"
info="$(cat "$status_file")"
rm -f "$status_file"

if [[ "$http_status" == "204" || -z "$info" || "$info" == "null" ]]; then
  is_active=false
  track=""
  artist=""
elif [[ "$http_status" == "200" ]]; then
  is_active="$(jq -r '.is_playing' <<<"$info")"
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

if [[ "$is_active" == "true" ]]; then
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
