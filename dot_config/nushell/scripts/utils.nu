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

def __herdr_current_tab_state [] {
    if ($env.HERDR_PANE_ID? | is-empty) {
        return null
    }

    try {
        let pane = (^herdr pane get $env.HERDR_PANE_ID | from json | get result.pane)
        let tab = (^herdr tab get $pane.tab_id | from json | get result.tab)

        {tab_id: $pane.tab_id, label: $tab.label, pane_count: $tab.pane_count}
    } catch {
        null
    }
}

export def --env herdr-wrap [label: string, command: closure] {
    let tab_state = (__herdr_current_tab_state)
    let use_tab_label = (($tab_state | is-not-empty) and ($tab_state.pane_count == 1))
    let previous_pane_label = (__herdr_current_pane_label)

    if ($env.HERDR_PANE_ID? | is-not-empty) {
        ^herdr pane rename $env.HERDR_PANE_ID $label | ignore
        if $use_tab_label {
            ^herdr tab rename $tab_state.tab_id $label | ignore
        }
    }

    try {
        do $command
    } finally {
        if ($env.HERDR_PANE_ID? | is-not-empty) {
            let current_pane_label = (__herdr_current_pane_label)
            if $current_pane_label == $label {
                if ($previous_pane_label | is-empty) {
                    ^herdr pane rename $env.HERDR_PANE_ID --clear | ignore
                } else {
                    ^herdr pane rename $env.HERDR_PANE_ID $previous_pane_label | ignore
                }
            }
            if $use_tab_label {
                let current_tab_state = (__herdr_current_tab_state)
                if ($current_tab_state | is-not-empty) and $current_tab_state.label == $label {
                    ^herdr tab rename $tab_state.tab_id $tab_state.label | ignore
                }
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
