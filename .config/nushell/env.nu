# default: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_env.nu

# ============================== PROMPT =======================================

$env.STARSHIP_SHELL = "nu"

def create_left_prompt [--hide] {
    let starship = if $hide == false {
        starship prompt --cmd-duration $env.CMD_DURATION_MS
    }
    $"($starship)(char newline)"
}

def create_character [type: string] {
    if $env.LAST_EXIT_CODE == 1 {
        return $'(ansi red_bold)x (ansi reset)'
    }

    let char = if $type == insert { '>' } else { '<' }
    $'(ansi green_bold)($char) (ansi reset)'
}

$env.PROMPT_COMMAND = { create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = ""
$env.TRANSIENT_PROMPT_COMMAND = { create_left_prompt --hide }
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ""

$env.PROMPT_MULTILINE_INDICATOR = "····· "
$env.PROMPT_INDICATOR_VI_INSERT = { create_character insert }
$env.PROMPT_INDICATOR_VI_NORMAL = { create_character normal }
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = { create_character insert }
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = { create_character normal }

# =============================== ENVS ========================================

def --env add_path [path: string] {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $path | uniq)
}

add_path ($env.HOME | path join .local bin)
add_path ($env.HOME | path join .local share bun bin)
add_path ($env.HOME | path join .local share mise shims)
add_path ($env.HOME | path join .local share pnpm)
# add_path ($env.HOME | path join .cargo bin)

hide add_path

$env.EDITOR = "vi"
$env.TERM = "xterm-256color" # if not set, will get "WARNING: terminal is not fully functional"
$env.GNUPGHOME = ($env.XDG_DATA_HOME | path join gnupg)

# $env.COLIMA_HOME = ($env.XDG_CONFIG_HOME | path join colima) # https://github.com/abiosoft/colima/issues/1236
$env.DOCKER_CONFIG = ($env.XDG_CONFIG_HOME | path join docker)
$env.DOCKER_HOST = $"unix://($env.HOME | path join .colima)/default/docker.sock"

$env.NPM_CONFIG_USERCONFIG = ($env.XDG_CONFIG_HOME | path join npm config)
$env.BUN_INSTALL = ($env.XDG_DATA_HOME | path join bun)
$env.DENO_INSTALL = ($env.XDG_DATA_HOME | path join deno)
$env.PNPM_HOME = ($env.XDG_DATA_HOME | path join pnpm)
$env.NU_LIB_DIRS = ($nu.default-config-dir | path join scripts)

$env.ZELLIJ_AUTO_ATTACH = true
$env.ZELLIJ_AUTO_EXIT = false

# colorizes manpages using bat
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"

# ========================== INITIALIZATION ===================================

# https://github.com/jdx/mise/issues/2768
# let mise_path = $nu.default-config-dir | path join scripts mise.gen.nu
# mise activate nu | save --force $mise_path

let zoxide_path = $nu.default-config-dir | path join scripts zoxide.gen.nu
zoxide init --cmd cd nushell | save --force $zoxide_path
