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
                | $"value(char tab)description(char newline)" + $in
                | from tsv --flexible --no-infer
            }
        }
    }

    table: {
        mode: light
    }

    # TODO customize, see ansi -l
    explore: {
        status_bar_background: { fg: "#1D1F21", bg: "dark_gray" },
        command_bar_text: { fg: "#C4C9C6" },
        highlight: { fg: "black", bg: "yellow" },
        status: {
            error: { fg: "white", bg: "red" },
            warn: {}
            info: {}
        },
        table: {
            split_line: { fg: "#404040" },
            selected_cell: { bg: light_blue },
            selected_row: {},
            selected_column: {},
        },
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
    use_grid_icons: false # show icons for command grid --color
    footer_mode: "30"
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
            name: ls
            modifier: control
            keycode: char_p
            mode: [emacs, vi_normal, vi_insert]
            event: [
                { edit: clear }
                { edit: insertstring, value: "lsa" }
                { send: enter }
            ]
        }
        {
            name: clear_scroll_back
            modifier: control
            keycode: char_n
            mode: [emacs, vi_normal, vi_insert]
            event: { send: clearscrollback }
        }
        {
            name: insert_newline
            modifier: alt
            keycode: enter
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: insertnewline }
        }
    ]
}

use mise.gen.nu
source zoxide.gen.nu

# Source scripts/*
source aliases.nu
source zellij-actions.nu
source youtube.nu
source ir-black.nu # https://github.com/nushell/nu_scripts/blob/f74b2aa7770a4c78ac7cb13fe2015f23ed9c597c/themes/nu-themes/ir-black.nu

if "ZELLIJ" not-in ($env | columns) {
    if $env.ZELLIJ_AUTO_ATTACH == true {
        zellij attach -c
    } else {
        zellij
    }

    if $env.ZELLIJ_AUTO_EXIT == true {
        exit
    }
}
