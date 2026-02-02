export def open-ports [] {
  lsof -i -P -n | grep LISTEN | lines | each {|line|
    let fields = ($line | split row -r '\\s+')
    {
      command: $fields.0
      pid: $fields.1
      address: ($fields | skip 8 | str join ' ')
    }
  }
}

export def kill-port [] {
  let ports = (open-ports)
  if ($ports | is-empty) {
    print "No listening TCP ports found."
    return
  }

  let max_cmd = ($ports | get command | each {|c| $c | str length } | math max)
  let max_pid = ($ports | get pid | each {|p| $p | str length } | math max)
  let max_addr = ($ports | get address | each {|a| $a | str length } | math max)

  let chosen = (
    $ports | each {|row|
      let cmd = ($row.command | fill -a l -c ' ' -w $max_cmd)
      let pid_str = ($row.pid | fill -a r -c ' ' -w $max_pid)
      let addr = ($row.address | fill -a l -c ' ' -w $max_addr)
      $"($cmd)\t($pid_str)\t($addr)"
    } | fzf --header="Select PID to kill"
  )

  if ($chosen | is-empty) {
    return
  }

  let pid = ($chosen | split row -r '\\s+' | get 3 | str trim)
  print $"Killing process ($pid)"
  kill ($pid | into int)
}

export def get-app-id [app_name: string] {
  let app_id = (ps | where name =~ $app_name | get id)
  if $app_id == "" {
    print $"No app found with name: ($app_name)"
    return
  }
  return $app_id
}
