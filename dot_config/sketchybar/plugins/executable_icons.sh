#!/usr/bin/env bash

# https://github.com/kvndrsslr/sketchybar-app-font

# Source the icon map with all the application icons
# shellcheck disable=SC1091
source "$CONFIG_DIR/external/sketchybar-app-font/dist/icon_map.sh"

# The upstream map knows only "Helium" and "Claude"; clones use names like "Helium Work".
name="${1/#Helium*/Helium}"
__icon_map "${name/#Claude Hadl/Claude}"

echo "${icon_result:-}"
