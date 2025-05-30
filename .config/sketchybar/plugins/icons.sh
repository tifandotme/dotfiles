#!/usr/bin/env bash

# Source the icon map with all the application icons
source "$CONFIG_DIR/icon_map.sh"

# Get icon from the mapping function
__icon_map "$1"

echo "$icon_result"
