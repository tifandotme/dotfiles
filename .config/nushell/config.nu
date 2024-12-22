# default: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu

# read default configurations
# > config env --default | nu-highlight | lines
# > config nu --default | nu-highlight | lines

$env.config = {
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
        status_bar_background: { fg: "#1D1F21", bg: "dark_gray" }
        command_bar_text: { fg: "#C4C9C6" }
        highlight: { fg: "black", bg: "yellow" }
        status: {
            error: { fg: "white", bg: "red" }
            warn: {}
            info: {}
        }
        table: {
            split_line: { fg: "#404040" },
            selected_cell: { bg: light_blue }
            selected_row: {}
            selected_column: {}
        }
    }

    filesize: {
        metric: true # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
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

    keybindings: [
        {
            name: complete_completion
            modifier: control
            keycode: space
            mode: [emacs, vi_normal, vi_insert]
            event: { send: historyhintcomplete }
        }
        {
            name: move_history_up
            modifier: control
            keycode: char_k
            mode: [emacs, vi_normal, vi_insert]
            event: { send: up }
        }
        {
            name: move_history_down
            modifier: control
            keycode: char_j
            mode: [emacs, vi_normal, vi_insert]
            event: { send: down }
        }
        {
            name: clear_scroll_back
            modifier: control
            keycode: char_n
            mode: [emacs, vi_normal, vi_insert]
            event: [
                { send: clearscrollback }
                { send: executehostcommand, cmd: "banner" }
            ]
        }
        {
            name: insert_newline
            modifier: alt
            keycode: enter
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: insertnewline }
        },
        {
            name: open_vscode
            modifier: control
            keycode: char_v
            mode: [emacs, vi_normal, vi_insert]
            event: {
                send: executehostcommand
                cmd: "code ."
            }
        },
        {
            name: history_menu
            modifier: control
            keycode: char_h
            mode: [vi_insert vi_normal]
            event: {
                until: [
                    { send: menu name: help_menu }
                    { send: menupagenext }
                ]
            }
        }
    ]
}

use mise.gen.nu
source zoxide.gen.nu

# Source scripts/*
source aliases.nu
source youtube.nu
source ir-black.nu # https://github.com/nushell/nu_scripts/blob/f74b2aa7770a4c78ac7cb13fe2015f23ed9c597c/themes/nu-themes/ir-black.nu

if "ZELLIJ" not-in ($env | columns) {
    if $env.ZELLIJ_AUTO_ATTACH == true {
        ^zellij attach -c
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
    let s_mem = (sys mem)
    let s_ho = (sys host)

    let tips = [
        "`cmds` to see all custom commands and aliases",
        "Ctrl-Z to open Zed in current directory",
        "Ctrl-V to open VSCode in current directory",
        "Ctrl-R to open history menu",
        "Ctrl-H to open help menu",
        "Inside lazygit, Ctrl+R to open repo in the browser",
        "`cdi` to run an interractive zoxide"
    ]

    print $"(ansi reset)(ansi green)($ellie.0)"
    print $"(ansi green)($ellie.1)  (ansi light_purple)  (ansi light_purple_bold)Uptime (ansi reset)(ansi light_purple)($s_ho.uptime)(ansi reset)"
    print $"(ansi green)($ellie.2)  (ansi light_blue)  (ansi light_blue_bold)RAM (ansi reset)(ansi light_blue)($s_mem.used) / ($s_mem.total)(ansi reset)"
    print $"(ansi green)($ellie.3)  (ansi yellow)  (ansi yellow_italic)($tips | shuffle | first)(ansi reset)"
}

if $nu.is-interactive {
    banner
}
