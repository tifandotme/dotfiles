#!/usr/bin/env bash

caffeinate_pid() {
  /usr/bin/pgrep -f "caffeinate -id" | /usr/bin/head -1
}

caffeinate_start() {
  /usr/bin/nohup /usr/bin/caffeinate -id </dev/null >/dev/null 2>&1 &
  disown
}

caffeinate_stop() {
  local pid
  pid=$(caffeinate_pid)
  [ -n "$pid" ] || return 1
  kill "$pid" 2>/dev/null
}

caffeinate_toggle() {
  if caffeinate_stop; then
    return
  fi
  caffeinate_start
}

caffeinate_icon() {
  if [ -n "$(caffeinate_pid)" ]; then
    printf '􂊭'
  fi
}
