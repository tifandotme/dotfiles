#!/usr/bin/env bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Helium (agent-browser enabled)
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🧪
# @raycast.packageName Browser

# Description:
# Launches Helium browser with Chrome DevTools Protocol (CDP) enabled on port 9222
# for use with agent-browser automation tool. This allows agent-browser to connect
# to Helium and perform automated browsing, screenshots, form filling, etc.
#
# Why this exists:
# agent-browser requires a browser with remote debugging enabled to control it
# programmatically. This script ensures Helium launches with the correct flags.
#
# Usage:
# 1. Run this script (or trigger via Raycast)
# 2. agent-browser will auto-discover the browser on port 9222
# 3. Or explicitly: agent-browser --cdp 9222 open <url>

# Quit existing Helium first
pkill -f "Helium" 2>/dev/null
sleep 0.5

# Launch Helium with remote debugging port for agent-browser
# Using 'open' ensures macOS system appearance (dark mode) is properly inherited
open -n -a Helium --args --remote-debugging-port=9222 --no-first-run &
