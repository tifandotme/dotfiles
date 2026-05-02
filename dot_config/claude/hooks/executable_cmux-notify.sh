#!/usr/bin/env bash

# Skip if not running inside cmux
[ -S /tmp/cmux.sock ] || exit 0

EVENT=$(cat)
EVENT_TYPE=$(echo "$EVENT" | jq -r '.hook_event_name // "unknown"')
TOOL=$(echo "$EVENT" | jq -r '.tool_name // ""')
MESSAGE=$(echo "$EVENT" | jq -r '.message // ""')

case "$EVENT_TYPE" in
"Notification")
  case "$MESSAGE" in
  *permission* | *"Permission"*)
    cmux notify --title "Claude Code" --subtitle "Action required" --body "Permission prompt waiting"
    ;;
  *idle* | *"waiting"*)
    cmux notify --title "Claude Code" --subtitle "Idle" --body "Waiting for your input"
    ;;
  *)
    cmux notify --title "Claude Code" --body "${MESSAGE:-Notification}"
    ;;
  esac
  ;;
"Stop")
  cmux notify --title "Claude Code" --subtitle "Done" --body "Session complete"
  ;;
"PostToolUse")
  [ "$TOOL" = "Task" ] && cmux notify --title "Claude Code" --subtitle "Agent" --body "Task finished"
  ;;
esac
