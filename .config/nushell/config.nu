# default: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu

# read default configurations
# > config env --default | nu-highlight | lines
# > config nu --default | nu-highlight | lines

# source: https://github.com/nushell/nu_scripts/blob/main/themes/nu-themes/ir-black.nu
# screenshot: https://raw.githubusercontent.com/nushell/nu_scripts/main/themes/screenshots/ir-black.png
let ir_black = {
    separator: "#b5b3aa"
    leading_trailing_space_bg: { attr: "n" }
    header: { fg: "#a8ff60" attr: "b" }
    empty: "#96cbfe"
    bool: {|| if $in { "#c6c5fe" } else { "light_gray" } }
    int: "#b5b3aa"
    filesize: {|e|
        if $e == 0b {
            "#b5b3aa"
        } else if $e < 1mb {
            "#c6c5fe"
        } else {{ fg: "#96cbfe" }}
    }
    duration: "#b5b3aa"
    date: {|| (date now) - $in |
        if $in < 1hr {
            { fg: "#ff6c60" attr: "b" }
        } else if $in < 6hr {
            "#ff6c60"
        } else if $in < 1day {
            "#ffffb6"
        } else if $in < 3day {
            "#a8ff60"
        } else if $in < 1wk {
            { fg: "#a8ff60" attr: "b" }
        } else if $in < 6wk {
            "#c6c5fe"
        } else if $in < 52wk {
            "#96cbfe"
        } else { "dark_gray" }
    }
    range: "#b5b3aa"
    float: "#b5b3aa"
    string: "#b5b3aa"
    nothing: "#b5b3aa"
    binary: "#b5b3aa"
    cellpath: "#b5b3aa"
    row_index: { fg: "#a8ff60" attr: "b" }
    record: "#b5b3aa"
    list: "#b5b3aa"
    block: "#b5b3aa"
    hints: "dark_gray"
    search_result: { fg: "#ff6c60" bg: "#b5b3aa" }

    shape_and: { fg: "#ff73fd" attr: "b" }
    shape_binary: { fg: "#ff73fd" attr: "b" }
    shape_block: { fg: "#96cbfe" attr: "b" }
    shape_bool: "#c6c5fe"
    shape_custom: "#a8ff60"
    shape_datetime: { fg: "#c6c5fe" attr: "b" }
    shape_directory: "#c6c5fe"
    shape_external: "#ff6c60" # changed, original #c5c5fe

    # TODO the original seems to be missing, so I added this manually. submit a PR?
    shape_external_resolved: { fg: "#ffffb6" attr: "b" }

    shape_externalarg: { fg: "#a8ff60" attr: "b" }
    shape_filepath: "#c6c5fe"
    shape_flag: { fg: "#96cbfe" attr: "b" }
    shape_float: { fg: "#ff73fd" attr: "b" }
    shape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: "b" }
    shape_globpattern: { fg: "#c6c5fe" attr: "b" }
    shape_int: { fg: "#ff73fd" attr: "b" }
    shape_internalcall: { fg: "#c6c5fe" attr: "b" }
    shape_list: { fg: "#c6c5fe" attr: "b" }
    shape_literal: "#96cbfe"
    shape_match_pattern: "#a8ff60"
    shape_matching_brackets: { attr: "u" }
    shape_nothing: "#c6c5fe"
    shape_operator: "#ffffb6"
    shape_or: { fg: "#ff73fd" attr: "b" }
    shape_pipe: { fg: "#ff73fd" attr: "b" }
    shape_range: { fg: "#ffffb6" attr: "b" }
    shape_record: { fg: "#c6c5fe" attr: "b" }
    shape_redirection: { fg: "#ff73fd" attr: "b" }
    shape_signature: { fg: "#a8ff60" attr: "b" }
    shape_string: "#a8ff60"
    shape_string_interpolation: { fg: "#c6c5fe" attr: "b" }
    shape_table: { fg: "#96cbfe" attr: "b" }
    shape_variable: "#ff73fd"

    background: "#000000"
    foreground: "#b5b3aa"
    cursor: "#b5b3aa"
}

$env.config = {
    # themes: https://github.com/nushell/nu_scripts/tree/main/themes
    color_config: $ir_black

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

use aliases.nu *
use youtube.nu *
use mise.gen.nu
source zoxide.gen.nu

if "ZELLIJ" not-in ($env | columns) {
    if $env.ZELLIJ_AUTO_ATTACH == true {
        ^(mise which zellij) attach -c
    } else {
    	^(mise which zellij)
    }

    if $env.ZELLIJ_AUTO_EXIT == true {
        exit
    }
}
