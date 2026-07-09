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

def __herdr_rename_pane [label: string] {
    if ($env.HERDR_PANE_ID? | is-not-empty) {
        ^herdr pane rename $env.HERDR_PANE_ID $label | ignore
    }
}

def __herdr_rename_tab [tab_id: string, label: string] {
    ^herdr tab rename $tab_id $label | ignore
}

def __herdr_restore_pane_label [label] {
    if ($env.HERDR_PANE_ID? | is-empty) {
        return
    }

    if ($label | is-empty) {
        ^herdr pane rename $env.HERDR_PANE_ID --clear | ignore
    } else {
        ^herdr pane rename $env.HERDR_PANE_ID $label | ignore
    }
}

def __herdr_restore_tab_label [tab_id: string, label: string] {
    ^herdr tab rename $tab_id $label | ignore
}

export def herdr-set-tab [label: string] {
    let tab_state = (__herdr_current_tab_state)
    if ($tab_state | is-not-empty) {
        __herdr_rename_tab $tab_state.tab_id $label
    }
}

export def --env herdr-wrap [label: string, command: closure, --tab] {
    let tab_state = (__herdr_current_tab_state)
    let use_tab_label = (($tab_state | is-not-empty) and ($tab or ($tab_state.pane_count == 1)))
    let previous_pane_label = (if $use_tab_label { null } else { __herdr_current_pane_label })

    if $use_tab_label {
        __herdr_rename_tab $tab_state.tab_id $label
    } else {
        __herdr_rename_pane $label
    }

    try {
        do $command
    } finally {
        if $use_tab_label {
            __herdr_restore_tab_label $tab_state.tab_id $tab_state.label
        } else {
            __herdr_restore_pane_label $previous_pane_label
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
