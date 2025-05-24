# alias lsblk = lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,FSAVAIL,MOUNTPOINT # linux only
alias rm = rm -rf
alias grep = grep --color=auto
alias diff = diff --color=auto
alias df = df --human-readable --si

# eza

alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all

# bat

alias _cat = cat
alias cat = bat --plain --theme=base16

alias bhelp = bat --language=help --paging=never --decorations=never --wrap=never

# Run a colored [cmd] -h
def h [command: string, ...args: string] {
    ^($command) ...$args -h | bhelp
}

# Run a colored [cmd] --help
def hh [command: string, ...args: string] {
    ^($command) ...$args --help | bhelp
}

hide bhelp

# gping

alias _ping = ping
alias ping = gping

# lazygit

alias lg = lazygit

alias g = git

# lazydocker

alias ld = lazydocker
alias _ld = ^ld # beware: `ld` is an existing program

# bun

alias b = bun

# pnpm

alias p = pnpm

# ncu

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json"

# gh (with copilot extension installed)

alias cos = gh copilot suggest
alias coe = gh copilot explain

# yadm

alias yal = yadm list -a
alias yag = yadm enter lazygit --work-tree ~

# Push all yadm changes
def yau [] {
    yadm add -u; yadm commit -m "update"; yadm push
}

# bottom

alias _btm = btm
def btm [] { run-with-tab-rename --name bottom btm -g }

# trafilatura

alias tf = trafilatura

# ------- yazi -------

# Run yazi (will cd into last directory when closed)
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")

    run-with-tab-rename --name yazi yazi ...$args --cwd-file $tmp
    # https://yazi-rs.github.io/docs/image-preview/#zellij (GUESS NOT NEEDED IN GHOSTTY)
    # TERM=xterm-kitty run-with-tab-rename --name yazi yazi ...$args --cwd-file $tmp

    let cwd = (open $tmp)
    if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
    }

    rm -fp $tmp
}

# ------- zellij -------

# Delete all zellij sessions (will close terminal window)
def zka [] {
    zellij delete-all-sessions --force --yes; zellij kill-all-sessions --yes
}

# Run a command and rename the tab (does not work with command that require an certain argument like `ncdu ~`)
def --wrapped run-with-tab-rename [
    --name: string
    command: string
    ...args: string
] {
    zellij action rename-tab $name
    do { ^$command ...$args }
    zellij action undo-rename-tab
}

# def nufzf [] {
#     # https://github.com/nushell/nushell/discussions/10859#discussioncomment-7413476
#     $in | each {|i| $i | to json --raw} | str join "\n" | fzf | from json
# }
