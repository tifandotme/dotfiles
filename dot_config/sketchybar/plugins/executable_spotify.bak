#!/bin/bash

set_spotify() {
  SPOTIFY="$(osascript -e 'tell application "Spotify" to get name of current track') - $(osascript -e 'tell application "Spotify" to get album of current track')"
  if ((${#SPOTIFY} < 31)); then # TODO adjust max chars
    sketchybar --set spotify icon="􀑪" \
      label="${SPOTIFY}"
  else
    sketchybar --set spotify icon="􀑪" \
      label="$(osascript -e 'tell application "Spotify" to get name of current track')"
  fi
}

# Check if Spotify is playing
case $(osascript -e 'tell application "Spotify" to get player state') in
"playing")
  set_spotify
  sketchybar --set spotify drawing=on
  ;;
*)
  # Hide completely when not playing
  sketchybar --set spotify drawing=off
  ;;
esac
