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

$env.EDITOR = "vi"
$env.TERMINFO = "/Applications/Ghostty.app/Contents/Resources/terminfo"
$env.TERM = "xterm-ghostty" # sometimes it's not set automatically
$env.GNUPGHOME = ($env.XDG_DATA_HOME | path join gnupg)

# $env.COLIMA_HOME = ($env.XDG_CONFIG_HOME | path join colima) # https://github.com/abiosoft/colima/issues/1236
$env.DOCKER_CONFIG = ($env.XDG_CONFIG_HOME | path join docker)
$env.DOCKER_HOST = $"unix://($env.XDG_CONFIG_HOME | path join colima)/default/docker.sock"

$env.NPM_CONFIG_USERCONFIG = ($env.XDG_CONFIG_HOME | path join npm config)
$env.BUN_INSTALL = ($env.XDG_DATA_HOME | path join bun)
$env.DENO_INSTALL = ($env.XDG_DATA_HOME | path join deno)
# $env.PNPM_HOME = ($env.XDG_DATA_HOME | path join pnpm)
$env.NU_LIB_DIRS = ($nu.default-config-dir | path join scripts)

$env.ANDROID_HOME = ($env.HOME | path join Library Android sdk)
$env.JAVA_HOME = "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"

$env.ZELLIJ_AUTO_ATTACH = true
$env.ZELLIJ_AUTO_EXIT = false

# colorizes manpages using bat
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"

# turns out there is a std lib (just found out 19 dec 2025)
# use std/util "path add"
# path add $"($nu.home-path)/.cargo/bin"

def --env add_path [path: string] {
  $env.PATH = ($env.PATH | split row (char esep) | prepend $path | uniq)
}

add_path ($env.HOME | path join .local bin)
add_path ($env.HOME | path join .local share bun bin)
add_path ($env.HOME | path join .local share mise shims)
# add_path ($env.HOME | path join .local share pnpm)
add_path ($env.HOME | path join .cargo bin)
add_path ($env.ANDROID_HOME | path join emulator)
add_path ($env.ANDROID_HOME | path join platform-tools)
add_path ($env.HOMEBREW_REPOSITORY | path join opt postgresql@18 bin)
add_path ($env.HOME | path join .antigravity antigravity bin)
# add_path ($env.NU_LIB_DIRS | path join external bash-env-json) # deleted during chezmoi migration, check if shit breaks

hide add_path

# https://www.nushell.sh/cookbook/ssh_agent.html#workarounds

do --env {
  let ssh_agent_file = (
    $nu.temp-dir | path join $"ssh-agent-(whoami).nuon"
  )

  if ($ssh_agent_file | path exists) {
    let ssh_agent_env = open ($ssh_agent_file)
    if ($"/proc/($ssh_agent_env.SSH_AGENT_PID)" | path exists) {
      load-env $ssh_agent_env
      return
    } else {
      rm $ssh_agent_file
    }
  }

  let ssh_agent_env = ^ssh-agent -c
    | lines
    | first 2
    | parse "setenv {name} {value};"
    | transpose --header-row
    | into record
  load-env $ssh_agent_env
  $ssh_agent_env | save --force $ssh_agent_file
}

# ========================== INITIALIZATION ===================================

# https://github.com/jdx/mise/issues/2768
# let mise_path = $nu.default-config-dir | path join scripts mise.gen.nu
# mise activate nu | save --force $mise_path
mkdir ~/.cache/mise; (^env -i (which 'mise' | first | get 'path') activate nu) | save --force ~/.cache/mise/init.nu

let zoxide_path = $nu.default-config-dir | path join scripts zoxide.gen.nu
zoxide init --cmd cd nushell | save --force $zoxide_path
