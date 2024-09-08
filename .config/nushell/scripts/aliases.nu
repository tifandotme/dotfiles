# NOTE possible workaround to define aliases conditionally:
# https://github.com/nushell/nushell/issues/5068#issuecomment-2094651642

alias rm = rm -rf
alias lsblk = lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,FSAVAIL,MOUNTPOINT # linux only
alias grep = grep --color=auto
alias diff = diff --color=auto
alias df = df --human-readable --si
def po [] {
  lsof -i -P -n | grep LISTEN
}

alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all

alias _cat = cat
alias cat = bat --plain --theme=base16

alias bhelp = bat --plain --language=help
def h [arg] {
  ^($arg) -h | bhelp
}
def hh [arg] {
  ^($arg) --help | bhelp
}

alias ncdu = ncdu --enable-delete --si

def up [] {
  brew upgrade
  mise upgrade --yes
  gh extension upgrade --all
  ya pack --upgrade
  bun update --global --latest
}

alias g = git

alias lg = lazygit

alias b = bun

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json" --packageManager bun

alias btm = btm -g

alias docker = podman

alias cos = gh copilot suggest
alias coe = gh copilot explain

alias z = zellij
def zka [] {
  zellij delete-all-sessions --force --yes; zellij kill-all-sessions --yes
}

alias yas = yadm status
alias yal = yadm list -a
alias yag = yadm enter lazygit --work-tree ~
def yau [] {
  yadm add -u; yadm commit -m 'update'; yadm push
}

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

def nufzf [] {
  # https://github.com/nushell/nushell/discussions/10859#discussioncomment-7413476
  $in | each {|i| $i | to json --raw} | str join "\n" | fzf | from json
}
