alias rm = rm -rf
alias lsblk = lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,FSAVAIL,MOUNTPOINT # linux only
alias grep = grep --color=auto
alias diff = diff --color=auto
alias df = df --human-readable --si

# Show all open ports
def po [] {
    lsof -i -P -n | grep LISTEN
}

alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all

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

alias ncdu = ncdu --enable-delete --si

# Update all packages
def up [] {
    print $"(ansi green_bold)==>(ansi reset) Upgrading (ansi green)brew(ansi reset) packages"
    brew upgrade

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)mise(ansi reset) packages"
    mise upgrade --yes

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)gh(ansi reset) extensions"
    gh extension upgrade --all

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)yazi(ansi reset) packages"
    ya pack --upgrade

    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)bun(ansi reset) global packages"
    bun update --global --latest

    # print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)pnpm(ansi reset) global packages"
    # pnpm update --global --latest
}

# Clean caches and uninstall unused packages (do this rarely)
def clean [] {
    mise prune
    pnpm store prune
    brew cleanup --prune=all
    brew autoremove
}

alias g = git

alias lg = lazygit

alias b = bun

alias p = pnpm

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json" --packageManager bun

alias btm = btm -g

# alias docker = podman

alias cos = gh copilot suggest
alias coe = gh copilot explain

alias z = zed

# Delete all zellij sessions (will close terminal window)
def zka [] {
    zellij delete-all-sessions --force --yes; zellij kill-all-sessions --yes
}

alias yal = yadm list -a
alias yag = yadm enter lazygit --work-tree ~

# Add and commit all changes in yadm
def yau [] {
    yadm add -u; yadm commit -m "update"; yadm push
}

# Run yazi (will cd into last directory when closed)
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    yazi ...$args --cwd-file $tmp

    let cwd = (open $tmp)
    if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
    }

    rm -fp $tmp
}

# List all custom commands and aliases (filtered by noteworthiness)
def cmds [] {
    let custom_excludes = [
        "drop", "banner", "lsblk", "update terminal", "_", "main", "pwd", "show", "next"
    ]

    help commands | where command_type =~ 'custom|alias' | reject params input_output search_terms category command_type | where name !~ ($custom_excludes | str join "|") | sort-by description
}

# def nufzf [] {
#     # https://github.com/nushell/nushell/discussions/10859#discussioncomment-7413476
#     $in | each {|i| $i | to json --raw} | str join "\n" | fzf | from json
# }
