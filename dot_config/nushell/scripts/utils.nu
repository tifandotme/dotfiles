def __herdr_current_pane_label [] {
    if ($env.HERDR_PANE_ID? | is-empty) {
        return null
    }

    try {
        ^herdr pane get $env.HERDR_PANE_ID
        | from json
        | get result.pane.label?
    } catch {
        null
    }
}

export def --env herdr-wrap [label: string, command: closure] {
    let previous_pane_label = (__herdr_current_pane_label)
    if ($env.HERDR_PANE_ID? | is-not-empty) {
        ^herdr pane rename $env.HERDR_PANE_ID $label | ignore
    }

    try {
        do $command
    } finally {
        if ($env.HERDR_PANE_ID? | is-not-empty) {
            if ($previous_pane_label | is-empty) {
                ^herdr pane rename $env.HERDR_PANE_ID --clear | ignore
            } else {
                ^herdr pane rename $env.HERDR_PANE_ID $previous_pane_label | ignore
            }
        }
    }
}

export def commands [] {
    let custom_excludes = [
        "drop"
        "banner"
        "lsblk"
        "update terminal"
        "_"
        "main"
        "pwd"
        "show"
        "next"
        "add"
    ]

    help commands
    | where command_type =~ 'custom|alias'
    | reject params input_output search_terms category command_type
    | where name !~ ($custom_excludes | str join "|")
    | sort-by description
}
