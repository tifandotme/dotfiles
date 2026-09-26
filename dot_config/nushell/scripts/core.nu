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

alias vim = nvim

def --wrapped nvimg [...args] {
    let git_root_result = git rev-parse --show-toplevel | complete

    if $git_root_result.exit_code != 0 {
        print -e "nvimg: not inside a git repository"
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

alias vimg = nvimg

alias g = git

def __helium_session_token [] {
    let db = (
        $nu.home-dir
        | path join "Library" "Application Support" "net.imput.helium" "Profile 1" "Cookies"
    )
    if not ($db | path exists) {
        error make {msg: $"Helium cookie database not found: ($db)"}
    }

    let key = (
        ^security find-generic-password -a Helium -s "Helium Storage Key" -w
        | str trim
    )
    let derived_key = (
        $key
        | encode utf-8
        | ^python3 -c 'import hashlib,sys; print(hashlib.pbkdf2_hmac("sha1",sys.stdin.buffer.read(),b"saltysalt",1003,16).hex())'
        | str trim
    )
    let encrypted = (
        ^sqlite3 $db
            "select hex(encrypted_value) from cookies where host_key=\"github.com\" and name=\"user_session\" order by last_update_utc desc limit 1"
        | str trim
    )
    if ($encrypted | is-empty) {
        error make {msg: "Helium has no github.com user_session cookie"}
    }

    $encrypted
    | decode hex
    | ^tail -c +4
    | ^openssl enc -d -aes-128-cbc -K $derived_key -iv 20202020202020202020202020202020 -nopad
    | ^python3 -c 'import sys; d=sys.stdin.buffer.read(); p=d[-1] if d else 0; value=d[32:-p] if 1 <= p <= 16 and d[-p:] == bytes([p]) * p else b""; assert value and all(32 <= c < 127 for c in value), "invalid Helium cookie"; sys.stdout.buffer.write(value)'
    | str trim
}

def --wrapped gh [...args: string] {
    if $args == ["image" "extract-token"] {
        let token = (__helium_session_token)
        print -e "Extracted session token from Helium main"
        return $token
    }

    ^gh ...$args
}

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
    let pi_config_dir = $env.PI_CODING_AGENT_DIR | path expand
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

    let pi_label = ([
        (pwd | path basename)
        " (pi)"
    ] | str join)
    herdr-wrap $pi_label {
        run-external (__external pi) ...$pi_args
    }
}

def __claude-sync-mcp-policy [] {
    let config = $env.XDG_CONFIG_HOME | path join "claude" ".claude.json"
    if not ($config | path exists) {
        error make {msg: $"Claude config not found: ($config)"}
    }

    let git_root = (^git rev-parse --show-toplevel | complete)
    let project = if $git_root.exit_code == 0 {
        $git_root.stdout | str trim
    } else {
        ^realpath (pwd) | str trim
    }
    let allowed = [
        "betterstack"
        "fff"
        "claude.ai Gmail"
        "claude.ai Google Calendar"
        "claude.ai Google Drive"
        "claude.ai Linear"
        "claude.ai PostHog"
        "claude.ai Slack"
    ]
    let blocked = [
        "claude.ai Asana"
        "claude.ai Atlassian"
        "claude.ai Attio"
        "claude.ai Box"
        "claude.ai Canva"
        "claude.ai Coda MCP"
        "claude.ai Figma"
        "claude.ai Gamma"
        "claude.ai Granola"
        "claude.ai HubSpot"
        "claude.ai Intercom"
        "claude.ai Jibble"
        "claude.ai Lovable"
        "claude.ai monday.com"
        "claude.ai Notion"
        "claude.ai Trello"
        "claude.ai Whimsical"
    ]
    let lock = $"($config).lock"
    let temporary = $"($config).tmp-(random uuid)"

    # ponytail: one global lock; separate locks per project if parallel launches matter
    try {
        mkdir $lock
    } catch {
        error make {msg: $"Another Claude MCP policy update owns the lock: ($lock)"}
    }
    try {
        let data = open --raw $config | from json
        let projects = (try { $data.projects } catch { {} })
        let state = (
            try {
                $projects | get $project
            } catch { {} }
        )
        let configured = (
            try {
                $state.mcpServers | columns
            } catch { [] }
        )
        let extra_blocked = $configured | where {|name|
            not ($allowed | any {|allowed_name| $allowed_name == $name})
        }
        let disabled = (
            (try { $state.disabledMcpServers } catch { [] })
            | append $blocked
            | append $extra_blocked
            | uniq
            | where {|name|
                not ($allowed | any {|allowed_name| $allowed_name == $name})
            }
            | sort
        )
        let next_state = $state | upsert disabledMcpServers $disabled
        let next_data = $data | upsert projects ($projects | upsert $project $next_state)
        if $next_data != $data {
            $next_data | to json --indent 2 | save --force $temporary
            ^chmod 600 $temporary
            mv -f $temporary $config
        }
    } catch {|error| error make {msg: $"Cannot update Claude MCP state: ($error.msg)"} } finally {
        if ($temporary | path exists) { rm -f $temporary }
        if ($lock | path exists) { rm -f $lock }
    }
}

def --wrapped claude [...args] {
    __claude-sync-mcp-policy
    let claude_label = ([
        (pwd | path basename)
        " (claude)"
    ] | str join)
    herdr-wrap $claude_label {
        run-external (__external claude) ...(["--dangerously-skip-permissions", "--no-chrome"] ++ $args)
    }
}

def --wrapped cliproxyapi [...args] {
    let config = $env.XDG_CONFIG_HOME | path join cliproxyapi config.yaml
    run-external (__external cliproxyapi) ...(["--config", $config] ++ $args)
}

def --wrapped claudex [...args] {
    let proxy_env = [
        [ANTHROPIC_BASE_URL "http://127.0.0.1:8317"]
        [ANTHROPIC_AUTH_TOKEN "sk-dummy"]
        [ANTHROPIC_DEFAULT_OPUS_MODEL "gpt-6-astra(medium)"]
        [ANTHROPIC_DEFAULT_SONNET_MODEL "gpt-6-sol(medium)"]
        [ANTHROPIC_DEFAULT_HAIKU_MODEL "gpt-6-luna(high)"]
    ] | into record
    with-env $proxy_env {
        claude ...$args
    }
}

alias _dotenvx = dotenvx
def --wrapped dotenvx [...args] {
    with-env {
        DOTENVX_NO_ARMOR: "true"
        DOTENVX_NO_1PASSWORD: "true"
    } {
        _dotenvx ...$args
    }
}

alias _codex = ^codex
def --wrapped codex [...args] { _codex --dangerously-bypass-approvals-and-sandbox ...$args }

alias _btm = btm

def --wrapped btm [...args] {
    herdr-wrap "btm" {
        _btm ...$args
    }
}

alias tf = trafilatura

alias _amp = amp
def --wrapped amp [...args] {
    let amp_label = ([
        (pwd | path basename)
        " (amp)"
    ] | str join)
    herdr-wrap $amp_label {
        with-env { AMP_REMOTE_CONTROL_TERMINAL: "1" } {
            _amp ...$args
        }
    }
}

alias _rg = rg
alias rg = rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview

def --wrapped gdu-go [...args] {
    let gdu_dir = if ($args | is-empty) {
        pwd
    } else {
        $args.0 | path expand
    }
    let gdu_label = [$gdu_dir " (gdu-go)"] | str join
    herdr-wrap $gdu_label {
        run-external (__external gdu-go) ...$args
    }
}
