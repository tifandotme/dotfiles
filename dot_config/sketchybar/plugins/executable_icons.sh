#!/usr/bin/env bash

# https://github.com/kvndrsslr/sketchybar-app-font

# Source the icon map with all the application icons
# shellcheck disable=SC1091
source "$CONFIG_DIR/external/sketchybar-app-font/dist/icon_map.sh"

# The upstream map knows only "Helium"; clones use names like "Helium Work".
__icon_map "${1/#Helium*/Helium}"

echo "${icon_result:-}"
