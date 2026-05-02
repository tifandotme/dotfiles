#!/usr/bin/env bash
set -u

payload="${1:-}"
message="Turn complete"

if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  parsed_message="$(
    printf '%s' "$payload" |
      jq -r '."last-assistant-message" // .message // "Turn complete"' 2>/dev/null |
      head -c 120
  )"

  if [ -n "$parsed_message" ] && [ "$parsed_message" != "null" ]; then
    message="$parsed_message"
  fi
fi

if command -v cmux >/dev/null 2>&1; then
  cmux notify --title "Codex" --body "$message"
  exit 0
fi

osascript -e 'on run argv
  display notification (item 1 of argv) with title "Codex"
end run' "$message"
