# default: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu

# read default configurations
# > config env --default | nu-highlight | lines
# > config nu --default | nu-highlight | lines

# Command to tab name mapping for zellij auto-rename
const ZELLIJ_CMD_MAP = {
  y: yazi
  yazi: yazi
  btm: bottom
  lzg: lazygit
  lazygit: lazygit
  spotify_player: spotify
  bandwhich: bandwhich
}

$env.config = {
  hooks: {
    env_change: {
      PWD: [
        {|before, after|
          if "ZELLIJ" not-in ($env | columns) { return }
          let base_name = ($after | path basename)
          $env._ZELLIJ_TAB_BASE_NAME = $base_name
          zellij action rename-tab $base_name
        }
      ]
    }
    pre_execution: [
      {
        if "ZELLIJ" not-in ($env | columns) { return }
        let cmdline = (commandline)
        if ($cmdline | is-empty) { return }

        let cmd = ($cmdline | str trim | split words | first)
        let program = ($ZELLIJ_CMD_MAP | get -o $cmd)

        if $program != null {
          let base = ($env._ZELLIJ_TAB_BASE_NAME? | default ($env.PWD | path basename))
          zellij action rename-tab $"($base) \(($program)\)"
          $env._ZELLIJ_TAB_RENAMED = true
        }
      }
    ]
    pre_prompt: [
      {
        if ($env._ZELLIJ_TAB_RENAMED? == true) {
          let base = ($env._ZELLIJ_TAB_BASE_NAME? | default ($env.PWD | path basename))
          zellij action rename-tab $base
          $env._ZELLIJ_TAB_RENAMED = false
        }
      }
    ]
  }
  completions: {
    external: {
      enable: true
      completer: {|spans|
        fish --command $'complete "--do-complete=($spans | str join " ")"'
        | from tsv --flexible --noheaders --no-infer
        | rename value description
      }
    }
  }

  table: {
    mode: light
  }

  # TODO customize, see ansi -l
  explore: {
    status_bar_background: {fg: "#1D1F21" bg: "dark_gray"}
    command_bar_text: {fg: "#C4C9C6"}
    highlight: {fg: "black" bg: "yellow"}
    status: {
      error: {fg: "white" bg: "red"}
      warn: {}
      info: {}
    }
    table: {
      split_line: {fg: "#404040"}
      selected_cell: {bg: light_blue}
      selected_row: {}
      selected_column: {}
    }
  }

  filesize: {
    unit: "metric" # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
  }

  cursor_shape: {
    emacs: line
    vi_insert: line
    vi_normal: block
  }

  show_banner: false
  footer_mode: "always"
  edit_mode: vi
  highlight_resolved_externals: true

  history: {
    file_format: "sqlite"
    max_size: 5_000_000
    isolation: false
  }

  keybindings: [
    {
      name: complete_completion
      modifier: control
      keycode: space
      mode: [emacs vi_normal vi_insert]
      event: {send: historyhintcomplete}
    }
    {
      name: move_history_up
      modifier: control
      keycode: char_k
      mode: [emacs vi_normal vi_insert]
      event: {send: up}
    }
    {
      name: move_history_down
      modifier: control
      keycode: char_j
      mode: [emacs vi_normal vi_insert]
      event: {send: down}
    }
    # { # unsed in go to bottom in list
    #   name: clear_scroll_back
    #   modifier: control
    #   keycode: char_n
    #   mode: [emacs vi_normal vi_insert]
    #   event: [
    #     {send: clearscrollback}
    #     {send: executehostcommand cmd: "banner"}
    #   ]
    # }
    {
      name: insert_newline
      modifier: alt
      keycode: enter
      mode: [emacs vi_normal vi_insert]
      event: {edit: insertnewline}
    }
    {
      name: help_menu
      modifier: control
      keycode: char_h
      mode: [vi_insert vi_normal]
      event: {
        until: [
          {send: menu name: help_menu}
          {send: menupagenext}
        ]
      }
    }
    {
      name: fzf_file_menu
      modifier: control
      keycode: char_t
      mode: [emacs vi_normal vi_insert]
      event: {send: menu name: fzf_file_menu}
    }
    {
      name: fzf_dir_menu
      modifier: control
      keycode: char_g
      mode: [emacs vi_normal vi_insert]
      event: {send: menu name: fzf_dir_menu}
    }
    {
      name: fzf_history
      modifier: control
      keycode: char_r
      mode: [emacs vi_normal vi_insert]
      event: {send: menu name: fzf_history}
    }
  ]

  menus: [
    {
      name: fzf_file_menu
      only_buffer_difference: true
      marker: "# "
      type: {
        layout: list
        page_size: 20
      }
      style: {
        text: "green"
        selected_text: {fg: "green" attr: r}
        description_text: yellow
      }
      source: {|buffer position|
        fd --type f --full-path $env.PWD
        | fzf -f $buffer | lines
        | each {|v| {value: ($v | str trim)} }
      }
    }
    {
      name: fzf_dir_menu
      only_buffer_difference: true
      marker: "# "
      type: {
        layout: list
        page_size: 20
      }
      style: {
        text: "green"
        selected_text: {fg: "green" attr: r}
        description_text: yellow
      }
      source: {|buffer position|
        fd --type d --full-path $env.PWD
        | fzf -f $buffer | lines
        | each {|v| {value: ($v | str trim)} }
      }
    }
    {
      name: fzf_history
      only_buffer_difference: true
      marker: "# "
      type: {
        layout: list
        page_size: 20
      }
      style: {
        text: "green"
        selected_text: {fg: "green" attr: r}
        description_text: yellow
      }
      source: {|buffer position|
        history | get command | uniq | reverse | str join (char nl)
        | fzf -f $buffer --tiebreak=index | lines
        | each {|v| {value: ($v | str trim)} }
      }
    }
  ]
}

# Guarded package managers
use chezmoi.nu [ bun brew ]
use chezmoi.nu

# Core aliases (must source for global shell usage)
source core.nu

# Domain modules
use git.nu
use docker.nu
use zellij.nu *
use media.nu *
use cloud.nu *
use system.nu *
use project.nu *
use dev.nu *
use utils.nu *

use updater.nu
use cert.nu

# use mise.gen.nu
source ~/.cache/mise/init.nu
source zoxide.gen.nu
use external/bash-env-nushell/bash-env.nu

if "ZELLIJ" not-in ($env | columns) {
  if $env.ZELLIJ_AUTO_ATTACH == true {
    ^zellij attach --create $env.USER
  } else {
    ^zellij
  }

  if $env.ZELLIJ_AUTO_EXIT == true {
    exit
  }
}

def banner [] {
  let ellie = [
    "     __  ,"
    " .--()°'.'"
    "'|, . ,'  "
    ' !_-(_\   '
  ]
  let s_disk = (sys disks | where mount == "/" | get 0)
  let s_ho = (sys host)

  let tips = [
    "`commands` to see all custom commands and aliases"
    "`cdi` to run an interractive zoxide"
    "Ctrl-Z to open Zed in current directory"
    "Ctrl-V to open VSCode in current directory"
    "Ctrl-R to open history menu"
    "Ctrl-I to open commands menu"
    "Ctrl-H to open help menu"
    "Inside lazygit, Ctrl+R to open repo in the browser"
  ]

  print $"(ansi reset)(ansi green)($ellie.0)"
  print $"(ansi green)($ellie.1)  (ansi light_purple)  (ansi light_purple_bold)Uptime (ansi reset)(ansi light_purple)($s_ho.uptime)(ansi reset)"
  print $"(ansi green)($ellie.2)  (ansi cyan)  (ansi cyan_bold)Disk (ansi reset)(ansi cyan)($s_disk.free | into filesize)(ansi reset)"
  print $"(ansi green)($ellie.3)  (ansi yellow)  (ansi yellow_italic)($tips | shuffle | first)(ansi reset)"
}

if $nu.is-interactive {
  banner
}
