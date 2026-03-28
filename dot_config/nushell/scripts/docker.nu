export def "stop-all" [--stop-colima (-c)] {
  docker stop ...(docker ps -aq | lines | str trim)
  if ($stop_colima) {
    colima stop
  }
}
