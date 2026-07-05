alias rm = rm -rf
alias grep = grep --color=auto

alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all

alias _cat = cat
alias cat = bat --plain --theme=base16

use utils.nu herdr-wrap

alias _tv = tv
def --wrapped tv [...args] {
    _tv --color-always --extend-width-and-length ...$args | bat --style plain
}

def --wrapped lazygit [...args] {
    let lzg_label = ([
        (pwd | path basename)
        " (lzg)"
    ] | str join)
    herdr-wrap $lzg_label {
    ^lazygit ...$args
  }
}

alias lzg = lazygit

def --wrapped lazydocker [...args] {
    let lzd_label = ([
        (pwd | path basename)
        " (lzd)"
    ] | str join)
    herdr-wrap $lzd_label {
    ^lazydocker ...$args
  }
}

alias lzd = lazydocker

alias d = docker

def --wrapped backlog [...args] {
    let backlog_label = ([
        (pwd | path basename)
        " (backlog)"
    ] | str join)
    herdr-wrap $backlog_label {
    ^backlog ...$args
  }
}

def --wrapped v [...args] {
    let nvim_label = ([
        (pwd | path basename)
        " (nvim)"
    ] | str join)
    herdr-wrap $nvim_label {
    ^nvim ...$args
  }
}

def --wrapped vg [...args] {
    let git_root_result = git rev-parse --show-toplevel | complete

    if $git_root_result.exit_code != 0 {
        print -e "vg: not inside a git repository"
        return
    }

    let git_root = $git_root_result.stdout | str trim
    let nvim_label = ([
        ($git_root | path basename)
        " (nvim)"
    ] | str join)
    herdr-wrap $nvim_label {
    cd $git_root
    ^nvim ...$args
  }
}

def --wrapped t [...args] {
    herdr-wrap --tab "tuxedo" {
    ^tuxedo ...$args
  }
}

alias g = git

alias b = bun
alias npx = bunx

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json"

alias cm = chezmoi

alias _pi = ^pi
def --wrapped pi [...args] {
    # pi-code-previews: avoid read/grep tool conflicts with pi-fff.
    # with-env {CODE_PREVIEW_TOOLS: "bash,write,edit,find,ls"} {
    _pi ...$args
}

alias _claude = ^claude
def --wrapped claude [...args] { _claude --dangerously-skip-permissions --no-chrome ...$args }

alias _codex = ^codex
def --wrapped codex [...args] { _codex --dangerously-bypass-approvals-and-sandbox ...$args }

alias _cursor-gui = ^cursor
def --wrapped cursor-gui [...args] {
    let cursor_config_dir = $env.HOME | path join ".cursor"
    with-env {CURSOR_CONFIG_DIR: $cursor_config_dir} {
    _cursor-gui --chat ...$args
  }
}

alias _cursor-agent = ^cursor-agent
def --wrapped cursor [...args] {
    let cursor_config_dir = $env.HOME | path join ".cursor"
    with-env {CURSOR_CONFIG_DIR: $cursor_config_dir} {
    _cursor-agent --yolo ...$args
  }
}

alias _btm = btm

alias tf = trafilatura

alias _amp = amp

alias _rg = rg
alias rg = rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview

alias gdu = gdu-go
