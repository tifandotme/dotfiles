use utils.nu herdr-wrap

export def get-app-id [app_name: string] {
    let app_id = ps | where name =~ $app_name | get id
    if $app_id == "" {
        print $"No app found with name: ($app_name)"
        return
    }
    return $app_id
}

export def --wrapped ssh [...args] {
    herdr-wrap $"> ($args | last | default remote)" {
        with-env {TERM: "xterm-256color"} { ^ssh ...$args }
    }
}

export def --wrapped sshs [...args] {
    let template = "nu -c \"source ~/.config/nushell/scripts/utils.nu; herdr-wrap '> {{#if user}}{{{user}}}@{{/if}}{{{destination}}}' { ^ssh '{{{name}}}' }\""
    let sshs_args = if ($env.HERDR_PANE_ID? | is-empty) {
        $args
    } else {
        $args ++ ["--template" $template]
    }

    herdr-wrap "> sshs" {
        with-env {TERM: "xterm-256color"} { ^sshs ...$sshs_args }
    }
}

export def --wrapped mosh [...args] {
    herdr-wrap $"> ($args | last | default remote)" {
        with-env {TERM: "xterm-256color"} { ^mosh ...$args }
    }
}

export def --env yazi [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    let yazi_label = ([
        (pwd | path basename)
        " (yazi)"
    ] | str join)
    herdr-wrap $yazi_label {
    ^yazi ...$args --cwd-file $tmp
  }
    let cwd = (open $tmp)
    if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
    }
    rm -fp $tmp
}

export alias y = yazi
