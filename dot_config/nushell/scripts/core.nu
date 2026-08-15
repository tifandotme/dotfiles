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

alias _nvim = ^nvim
def --wrapped nvim [...args] {
    let nvim_label = ([
        (pwd | path basename)
        " (nvim)"
    ] | str join)
    herdr-wrap $nvim_label {
        _nvim ...$args
    }
}

alias v = nvim

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
        _nvim ...$args
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

def __external [name: string] {
    ^which $name | str trim
}

def --wrapped pi [...args] {
    if ($args | any {|arg|
        $arg == "--mcp-config" or ($arg | str starts-with "--mcp-config=")
    }) {
        error make {msg: "pi selects the MCP config from the current directory; do not pass --mcp-config"}
    }

    let real_cwd = (^realpath (pwd) | str trim)
    let work_root = (^realpath ($env.HOME | path join "projects" "work") | str trim)
    let pi_config_dir = (
        $env
        | get -o PI_CODING_AGENT_DIR
        | default ($env.HOME | path join ".config" "pi")
        | path expand
    )
    let config_name = if (
        $real_cwd == $work_root
        or ($real_cwd | str starts-with $"($work_root)(char separator)")
    ) {
        "mcp-work.json"
    } else {
        "mcp-personal.json"
    }
    let mcp_config = $pi_config_dir | path join $config_name

    if not ($mcp_config | path exists) {
        error make {msg: $"MCP config not found: ($mcp_config)"}
    }

    # Package commands must be first; they do not use the MCP config.
    let package_commands = [
        "install"
        "remove"
        "uninstall"
        "update"
        "list"
        "config"
        "auth"
    ]
    let first_arg = if ($args | is-empty) { "" } else { $args.0 }
    let pi_args = if $first_arg in $package_commands {
        $args
    } else {
        ["--mcp-config" $mcp_config] ++ $args
    }

    # pi-code-previews: avoid read/grep tool conflicts with pi-fff.
    # with-env {CODE_PREVIEW_TOOLS: "bash,write,edit,find,ls"} {
    run-external (__external pi) ...$pi_args
}

def --wrapped claude [...args] {
    run-external (__external claude) ...(["--dangerously-skip-permissions", "--no-chrome"] ++ $args)
}

def --wrapped cliproxyapi [...args] {
    let config = $env.XDG_CONFIG_HOME | path join cliproxyapi config.yaml
    run-external (__external cliproxyapi) ...(["--config", $config] ++ $args)
}

def --wrapped claudex [...args] {
    let proxy_env = [
        [ANTHROPIC_BASE_URL "http://127.0.0.1:8317"]
        [ANTHROPIC_AUTH_TOKEN "sk-dummy"]
        [ANTHROPIC_DEFAULT_OPUS_MODEL "gpt-5.6-sol(medium)"]
        [ANTHROPIC_DEFAULT_SONNET_MODEL "gpt-5.6-terra(high)"]
        [ANTHROPIC_DEFAULT_HAIKU_MODEL "gpt-5.6-luna(high)"]
    ] | into record
    with-env $proxy_env {
        claude ...$args
    }
}

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
