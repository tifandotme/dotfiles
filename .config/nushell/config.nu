# default: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu

# read default configurations
# > config env --default | nu-highlight | lines
# > config nu --default | nu-highlight | lines

$env.config = {
    # themes: https://github.com/nushell/nu_scripts/tree/main/themes
    color_config: (use ir-black.nu; ir-black)

    show_banner: false

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

    # completions: {
    #     quick: true    # set this to false to prevent auto-selecting completions when only one remains
    #     partial: true    # set this to false to prevent partial filling of the prompt
    #     algorithm: "prefix"    # prefix or fuzzy
    #     external: {
    #         enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up may be very slow
    #         max_results: 100 # setting it lower can improve completion performance at the cost of omitting some options
    #         completer: null
    #     }
    # }

    filesize: {
        metric: true # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
    }

    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }

    use_grid_icons: false # show icons for command grid --color
    footer_mode: "30" # always, never, number_of_rows, auto
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
            modifier: alt
            keycode: char_k
            mode: [emacs, vi_normal, vi_insert]
            event: { send: up }
        }
        {
            name: move_history_down
            modifier: alt
            keycode: char_j
            mode: [emacs, vi_normal, vi_insert]
            event: { send: down }
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

use mise.nu
use aliases.nu *
source zoxide.nu
