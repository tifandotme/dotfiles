export alias z = zellij

export def zka [] {
  zellij delete-all-sessions --force --yes
  zellij kill-all-sessions --yes
}

export def --wrapped run-with-tab-rename [
  --name: string
  command: string
  ...args: string
] {
  zellij action rename-tab $name
  do { ^$command ...$args }
  zellij action undo-rename-tab
}

export def --wrapped btm [...args] {
  run-with-tab-rename --name [bottom] btm -g --process_memory_as_value ...$args
}

export def --wrapped amp [...args] {
  EDITOR=zed _amp ...$args
}

export def --wrapped sshs [...args] {
  TERM=xterm-256color ^sshs ...$args
}

export def spo [] {
  TERM="xterm-256color" run-with-tab-rename --name [spotify] spotify_player
}

export def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  run-with-tab-rename --name [yazi] yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -fp $tmp
}

export def bandwhich [] {
  run-with-tab-rename --name [bandwhich] sudo bandwhich
}
