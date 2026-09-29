#!/usr/bin/env bash
set -euo pipefail

AEROSPACE=/opt/homebrew/bin/aerospace
monitor_name="$($AEROSPACE list-monitors --focused --format '%{monitor-name}')"
app_id="$($AEROSPACE list-windows --focused --format '%{app-bundle-id}')"

case "$app_id:$monitor_name" in
com.mitchellh.ghostty:H24G30Q) action=ghostty15 ;;
com.mitchellh.ghostty:*) action=ghostty14 ;;
club.refactoring.tolaria:H24G30Q) action=tolaria130 ;;
club.refactoring.tolaria:*) action=tolaria100 ;;
com.tinyspeck.slackmacgap:H24G30Q) action=slack_zoom_in ;;
com.tinyspeck.slackmacgap:*) action=slack_reset ;;
*) exit 0 ;;
esac

/usr/bin/osascript - "$action" <<'APPLESCRIPT'
on run argv
  set profileAction to item 1 of argv

  if profileAction is "ghostty15" or profileAction is "ghostty14" then
    if profileAction is "ghostty15" then
      set fontSize to "15"
    else
      set fontSize to "14"
    end if
    tell application "Ghostty"
      try
        set terminalSurface to focused terminal of selected tab of front window
        perform action ("set_font_size:" & fontSize) on terminalSurface
      end try
    end tell
  else if profileAction is "tolaria130" or profileAction is "tolaria100" then
    tell application "System Events"
      tell process "tolaria"
        keystroke "0" using {command down}
        if profileAction is "tolaria130" then
          repeat 3 times
            keystroke "=" using {command down}
          end repeat
        end if
      end tell
    end tell
  else if profileAction is "slack_zoom_in" or profileAction is "slack_reset" then
    tell application "System Events"
      tell process "Slack"
        keystroke "0" using {command down}
        delay 0.2
        if profileAction is "slack_zoom_in" then
          keystroke "=" using {command down, shift down}
        end if
      end tell
    end tell
  end if
end run
APPLESCRIPT
