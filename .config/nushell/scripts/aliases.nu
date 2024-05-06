# NOTE possible workaround to define export aliases conditionally:
# https://github.com/nushell/nushell/issues/5068#issuecomment-2094651642

# coreutils
export alias rm = rm -rf

# bun
export alias b = ^bun

# zellij
export alias z = ^zellij
export alias zrf = ^zellij run --floating --

# helix deez
export alias h = ^hx

export alias core-ls = ls
def old-ls [
  --all
  path
] {
    let lses = if $all {
      core-ls --all --mime-type $path
    } else {
      core-ls --mime-type $path
    }
    let dirs = $lses | where type == dir | sort-by --ignore-case name
    let files = $lses | where type !~ dir | sort-by --ignore-case type name
    $dirs | append $files | grid --color --separator '   '
}
export def ls [path?] {
  if $path == null {
    old-ls .
  } else {
    old-ls $path
  }
}
export def lsa [path?] {
  if $path == null {
    old-ls --all .
  } else {
    old-ls --all $path
  }
}
