# NOTE possible workaround to define aliases conditionally:
# https://github.com/nushell/nushell/issues/5068#issuecomment-2094651642

# coreutils
alias rm = rm -rf
alias lsblk = lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,FSAVAIL,MOUNTPOINT # linux only
alias grep = grep --color=auto
alias diff = diff --color=auto
def po [] {
  lsof -i -P -n | grep LISTEN
}
alias df = df --human-readable --si

# up (macos)
def up [] {
  brew upgrade
  mise upgrade --yes
  gh extension upgrade --all
  bun update --global --latest
}

# git
alias g = git

# bun
alias b = bun

# zellij
alias z = zellij
alias zrf = zellij run --floating --

# copilot cli
alias cos = gh copilot suggest
alias coe = gh copilot explain

# ncdu
alias ncdu = ncdu --enable-delete --si

# bat
alias bhelp = bat --plain --language=help

# bottom
alias btm = btm -g

# podman
alias docker = podman

# yadm
alias yas = yadm status
alias yal = yadm list -a
alias yag = yadm enter lazygit --work-tree ~
def yau [] {
  yadm add -u; yadm commit -m 'update'; yadm push
}

# lazygit
alias lg = lazygit

# yazi
alias _yazi = yazi
def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  _yazi ...$args --cwd-file $tmp

  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -fp $tmp
}
alias yazi = y

# npm-check-updats
alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json" --packageManager bun

# fzf
# https://github.com/nushell/nushell/discussions/10859#discussioncomment-7413476
def nufzf [] { $in | each {|i| $i | to json --raw} | str join "\n" | fzf | from json }

# ls
alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all
# def print_grid_ls [
#   --all
#   path
# ] {
#     let lses = if $all {
#       _ls --all --mime-type $path
#     } else {
#       _ls --mime-type $path
#     }
#     let dirs = $lses | where type == dir | sort-by --ignore-case name
#     let files = $lses | where type !~ dir | sort-by --ignore-case type name
#     $dirs | append $files | grid --color --separator '   '
# }
# def ls [path?] {
#   if $path == null {
#     print_grid_ls .
#   } else {
#     print_grid_ls $path
#   }
# }
# def lsa [path?] {
#   if $path == null {
#     print_grid_ls --all .
#   } else {
#     print_grid_ls --all $path
#   }
# }
