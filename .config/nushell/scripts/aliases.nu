# NOTE possible workaround to define export aliases conditionally:
# https://github.com/nushell/nushell/issues/5068#issuecomment-2094651642

# coreutils
export alias rm = rm -rf
export alias lsblk = lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,FSAVAIL,MOUNTPOINT
export alias grep = grep --color=auto
export alias diff = diff --color=auto
export def po [] {
  lsof -i -P -n | grep LISTEN
}
export alias df = df --human-readable --si

# git
export alias g = git

# bun
export alias b = bun

# zellij
export alias z = zellij
export alias zrf = zellij run --floating --

# helix deez
export alias h = hx

# ncdu
export alias ncdu = ncdu --enable-delete --si

# bat
export alias bhelp = bat --plain --language=help

# bottom
export alias btm = btm -g

# podman
export alias docker = podman

# yadm (soon to be replaced?)
export alias yas = yadm status
export alias yal = yadm list -a
export alias yag = yadm enter lazygit --work-tree ~
export def yau [] {
  yadm add -u; yadm commit -m 'update'; yadm push
}

# yazi
export def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  yazi ...$args --cwd-file $tmp

  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -fp $tmp
}

# npm-check-updats
export alias _ncu = ncu
export alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json" --packageManager bun

# ls
export alias _ls = ls
def print_grid_ls [
  --all
  path
] {
    let lses = if $all {
      _ls --all --mime-type $path
    } else {
      _ls --mime-type $path
    }
    let dirs = $lses | where type == dir | sort-by --ignore-case name
    let files = $lses | where type !~ dir | sort-by --ignore-case type name
    $dirs | append $files | grid --color --separator '   '
}
export def ls [path?] {
  if $path == null {
    print_grid_ls .
  } else {
    print_grid_ls $path
  }
}
export def lsa [path?] {
  if $path == null {
    print_grid_ls --all .
  } else {
    print_grid_ls --all $path
  }
}
