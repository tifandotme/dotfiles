def __worktree-root [project: string] {
    let projects_dir = $env.XDG_PROJECTS_DIR
    let personal_dir = $projects_dir | path join 'personal'
    if $project == $personal_dir or ($project | str starts-with $"($personal_dir)/") {
        return ($personal_dir | path join '.worktrees')
    }
    $projects_dir | path join 'work' '.worktrees'
}

def __new-worktree-path [project: string] {
    let root = (__worktree-root $project)
    let repo_root = $root | path join ($project | path basename)
    if not ($repo_root | path exists) {
        mkdir $repo_root | ignore
    }

    ^mktemp -d ($repo_root | path join "worktree-XXXXXXXX") | str trim
}

def __project-dirs [] {
    mut project_dirs = []
    let projects_dir = $env.XDG_PROJECTS_DIR

    for base in [
        ($projects_dir | path join 'personal')
        ($projects_dir | path join 'work')
    ] {
        if not ($base | path exists) {
            continue
        }
        let base_dirs = _ls $base | where type == dir | get name
        for dir in $base_dirs {
            if (($dir | path basename) | str starts-with '@') {
                let sub_dirs = _ls $dir | where type == dir | get name
                $project_dirs = ($project_dirs | append $sub_dirs | flatten)
            } else {
                $project_dirs = ($project_dirs | append $dir)
            }
        }
    }

    $project_dirs | sort
}

def __git-worktree-inventory [project: string] {
    let result = (^git -C $project worktree list --porcelain | complete)
    if $result.exit_code != 0 {
        return null
    }

    mut worktrees = []
    mut current = {path: "", branch: "(detached)"}
    mut has_current = false
    for line in ($result.stdout | lines) {
        if ($line | str starts-with "worktree ") {
            if $has_current {
                $worktrees = ($worktrees | append $current)
            }
            $current = {
                path: ($line | str replace "worktree " "")
                branch: "(detached)"
            }
            $has_current = true
        } else if ($line | str starts-with "branch ") and $has_current {
            let branch = $line | str replace "branch " "" | str replace "refs/heads/" ""
            $current.branch = $branch
        }
    }

    if $has_current {
        $worktrees = ($worktrees | append $current)
    }

    {
        project: $project
        worktrees: (
            $worktrees
            | where path != $project
            | where {|worktree| $worktree.path | path exists }
        )
    }
}

def __relative-home [path: string] {
    let prefix = $"($env.HOME)/"
    if ($path | str starts-with $prefix) {
        $path | str replace $prefix "~/"
    } else {
        $path
    }
}

def __pr-check-summary [checks] {
    let reset = (ansi reset)
    let green = (ansi green_bold)
    let red = (ansi red_bold)
    let yellow = (ansi yellow_bold)
    let muted = (ansi dark_gray_dimmed)
    if ($checks | is-empty) {
        return $"($muted)none($reset)"
    }

    let check_states = ($checks | each {|check|
        let conclusion = (try { $check.conclusion } catch { "" })
        let raw_state = if ($conclusion | is-not-empty) {
            $conclusion
        } else {
            try { $check.state } catch {
                try { $check.status } catch { "" }
            }
        }
        let state = $raw_state | str uppercase
        if $state in ["SUCCESS" "NEUTRAL" "SKIPPED"] {
            "pass"
        } else if $state in ["FAILURE" "ERROR" "CANCELLED" "TIMED_OUT" "ACTION_REQUIRED"] {
            "fail"
        } else {
            "pending"
        }
    })
    let passed = $check_states | where {|state| $state == "pass" } | length
    let failed = $check_states | where {|state| $state == "fail" } | length
    let pending = $check_states | where {|state| $state == "pending" } | length
    mut parts = []
    if $passed > 0 {
        $parts = ($parts | append $"($green)($passed) passed($reset)")
    }
    if $failed > 0 {
        $parts = ($parts | append $"($red)($failed) failed($reset)")
    }
    if $pending > 0 {
        $parts = ($parts | append $"($yellow)($pending) pending($reset)")
    }
    $parts | str join ", "
}

def __terminal-link [text: string, url: string] {
    let esc = (char --unicode '1b')
    let bel = (char --unicode '07')
    $"($esc)]8;;($url)($bel)($text)($esc)]8;;($bel)"
}

def __preview-prs [path: string, branch: string] {
    let reset = (ansi reset)
    let label = (ansi cyan_bold)
    let green = (ansi green_bold)
    let cyan = (ansi cyan_bold)
    let red = (ansi red_dimmed)
    let yellow = (ansi yellow_bold)
    let link_color = (ansi --escape {fg: "#60a5fa", attr: u})
    let muted = (ansi dark_gray_dimmed)
    let cache_root = $env.XDG_CACHE_HOME | path join "nushell" "project-prs"
    let cache_key = [$path $branch "with-url"] | str join "\n" | hash sha256
    let cache_file = $cache_root | path join $"($cache_key).json"
    let cached = (
        try {
            let cache_info = ls $cache_file | first
            if (((date now) - $cache_info.modified) < 1min) {
                open $cache_file | get prs
            } else {
                null
            }
        } catch { null }
    )
    let prs = if $cached == null {
        let result = (do {
            cd $path
            ^gh pr list --head $branch --state all --limit 30 --json number,title,state,isDraft,baseRefName,statusCheckRollup,url
        } | complete)
        if $result.exit_code != 0 {
            print $"($label)PR:($reset) ($yellow)unavailable($reset)"
            return
        }

        let fresh_prs = (
            try { $result.stdout | from json } catch { [] }
        )
        try {
            mkdir $cache_root | ignore
            {prs: $fresh_prs} | to json | save -f $cache_file
        } catch { }
        $fresh_prs
    } else {
        $cached
    }
    if ($prs | is-empty) {
        print $"($label)PR:($reset) ($muted)none($reset)"
        return
    }

    mut ordered_prs = $prs | where state == "OPEN"
    $ordered_prs = ($ordered_prs | append ($prs | where state != "OPEN"))
    print $"($label)PRs:($reset) ($ordered_prs | length)"
    for pr in $ordered_prs {
        let state_color = if $pr.state == "OPEN" {
            $green
        } else if $pr.state == "MERGED" {
            $cyan
        } else {
            $red
        }
        let draft = if $pr.isDraft { $"  ($yellow)DRAFT($reset)" } else { "" }
        let url = (try { $pr.url } catch { "" })
        let number = if ($url | is-empty) {
            $"#($pr.number)"
        } else {
            let link = (__terminal-link $"#($pr.number)" $url)
            $"($link_color)($link)($reset)"
        }
        print $"($number)  ($state_color)($pr.state)($reset)  -> ($pr.baseRefName)($draft)"
        print $"  ($pr.title)"
        if $pr.state == "OPEN" {
            let checks = (try { $pr.statusCheckRollup } catch { [] })
            print $"  Checks: (__pr-check-summary $checks)"
        }
    }
}

def __worktree-preview [kind: string, path: string, branch: string] {
    let reset = (ansi reset)
    let label = (ansi cyan_bold)
    let green = (ansi green_bold)
    let red = (ansi red_bold)
    let action = if $kind == "worktree" {
        "Enter: open and focus this worktree"
    } else {
        "Enter: create and focus an auto-named worktree from this project"
    }
    print $"($label)($action)($reset)"
    print ""

    let git_status = (^git -C $path status --short | complete)
    if $git_status.exit_code != 0 {
        print $"($label)Git:($reset) ($red)unavailable($reset)"
    } else {
        let status = $git_status.stdout | str trim
        if ($status | is-empty) {
            print $"($label)Git:($reset) ($green)clean($reset)"
        } else {
            print $"($label)Git:($reset) ($red)dirty($reset)"
            print $status
        }
    }

    if $kind == "worktree" {
        print ""
        __preview-prs $path $branch
    }
}

def __tree-row [
    kind: string
    project: string
    path: string
    branch: string
    display: string
] {
    [
        $kind
        $project
        $path
        $branch
        $display
    ] | str join (char tab)
}

def __project-rows [] {
    let reset = (ansi reset)
    let project_color = (ansi cyan_bold)
    let marker_color = (ansi dark_gray)
    let branch_color = (ansi green_bold)
    let path_color = (ansi dark_gray_dimmed)
    mut rows = []

    for project in (__project-dirs) {
        let inventory = (__git-worktree-inventory $project)
        if $inventory == null {
            continue
        }

        let project_display = $project | path basename
        let display = $"($project_color)($project_display)($reset)"
        $rows = (
            $rows
            | append (
                (__tree-row
                    "create"
                    $project
                    $project
                    ""
                    $display
                )
            )
        )

        let last_worktree_index = ($inventory.worktrees | length) - 1
        for entry in ($inventory.worktrees | enumerate) {
            let worktree = $entry.item
            let branch_marker = if $entry.index == $last_worktree_index { "└─" } else { "├─" }
            let display = [
                $"($marker_color)($branch_marker)($reset)"
                $"($branch_color)($worktree.branch)($reset)"
                $"($path_color)(__relative-home $worktree.path)($reset)"
            ] | str join "  "
            $rows = (
                $rows
                | append (
                    (__tree-row
                        "worktree"
                        $project
                        $worktree.path
                        $worktree.branch
                        $display
                    )
                )
            )
        }
    }

    $rows
}

def __project-rows-output [] {
    __project-rows | str join "\n"
}

def __worktree-dialog [header: string, options: list<string>] {
    mut fzf_args = [
        "--ansi"
        "--style" "minimal"
        "--border" "none"
        "--layout" "reverse-list"
        "--info" "hidden"
        "--no-scrollbar"
        "--no-input"
        "--pointer" ">"
        "--color"
        "fg:-1,bg:-1,fg+:-1,bg+:-1,pointer:cyan,prompt:cyan,header:yellow"
    ]
    if ($header | is-not-empty) {
        $fzf_args = ($fzf_args | append ["--header" $header "--header-first"])
    }
    $options | str join "\n" | ^fzf ...$fzf_args | str trim
}

def __worktree-notice [header: string] {
    __worktree-dialog $header ["Back"] | ignore
}

def __close-worktree [kind: string, project: string, path: string] {
    if $kind != "worktree" {
        __worktree-notice "Only existing worktrees can be closed."
        return
    }

    let git_status = (^git -C $path status --porcelain | complete)
    if $git_status.exit_code != 0 {
        __worktree-notice "Cannot inspect worktree status."
        return
    }
    if ($git_status.stdout | str trim | is-not-empty) {
        let header = [
            "Cannot close a dirty worktree."
            "Commit or clean it first."
        ] | str join (char nl)
        __worktree-notice $header
        return
    }

    let lookup = (^herdr worktree list --cwd $path | complete)
    if $lookup.exit_code != 0 {
        __worktree-notice "Cannot find the Herdr workspace for this worktree."
        return
    }
    let payload = (
        try {
            $lookup.stdout | from json
        } catch { null }
    )
    let worktree = (
        try {
            $payload.result.worktrees
            | where path == $path
            | first
        } catch { null }
    )
    if $worktree == null {
        __worktree-notice "Cannot find the selected worktree."
        return
    }
    let workspace_id = (try { $worktree.open_workspace_id } catch { "" })

    let choice = (__worktree-dialog "Close worktree?" ["No" "Yes"])
    if $choice != "Yes" {
        return
    }

    if ($workspace_id | is-empty) {
        let removed = (^git -C $project worktree remove $path | complete)
        if $removed.exit_code != 0 {
            let reason = $removed.stderr | str trim
            let header = if ($reason | is-empty) {
                "Git could not close the worktree."
            } else {
                $"Git could not close the worktree:\n($reason)"
            }
            __worktree-notice $header
        }
        return
    }

    let removed = (^herdr worktree remove --workspace $workspace_id | complete)
    if $removed.exit_code != 0 {
        let reason = $removed.stderr | str trim
        let header = if ($reason | is-empty) {
            "Herdr could not close the worktree."
        } else {
            $"Herdr could not close the worktree:\n($reason)"
        }
        __worktree-notice $header
    }
}

export def --env open-project [default_project: string = ""] {
    try {
        let delimiter = (char tab)
        let preview = "env PWD=\"$HOME\" FZF_KIND={1} FZF_PATH={3} FZF_BRANCH={4} nu -c 'source ~/.config/nushell/scripts/project.nu; __worktree-preview $env.FZF_KIND $env.FZF_PATH $env.FZF_BRANCH'"
        let close = "env PWD=\"$HOME\" FZF_KIND={1} FZF_PROJECT={2} FZF_PATH={3} nu -c 'source ~/.config/nushell/scripts/project.nu; __close-worktree $env.FZF_KIND $env.FZF_PROJECT $env.FZF_PATH'"
        let reload = "env PWD=\"$HOME\" nu -c 'source ~/.config/nushell/scripts/core.nu; source ~/.config/nushell/scripts/project.nu; __project-rows-output'"
        let close_binding = "ctrl-x:execute(" + $close + ")+reload(" + $reload + ")"

        let rows = (__project-rows)
        if ($rows | is-empty) {
            print "No Git projects found."
            return
        }

        mut fzf_args = [
            "--ansi"
            "--delimiter" $delimiter
            "--with-nth" "5"
            "--no-sort"
            "--layout" "reverse-list"
            "--prompt" "worktree> "
            "--footer" "Enter open/create  •  Ctrl-X close  •  Esc cancel"
            "--bind" $close_binding
            "--color"
            "fg:-1,bg:-1,fg+:-1,bg+:-1,hl:cyan,hl+:cyan,pointer:magenta,prompt:cyan,footer:yellow,marker:green"
            "--preview" $preview
            "--preview-window" "right:45%"
            "--preview-label" " details "
        ]
        if ($default_project | is-not-empty) {
            $fzf_args = ($fzf_args | append $"--query=($default_project)")
        }

        let fzf_result = (
                $rows
                | str join "\n"
                | ^fzf ...$fzf_args
                | complete
            )
        let output = $fzf_result.stdout
        if ($output | is-empty) {
            return
        }
        let output_lines = $output | lines
        if ($output_lines | is-empty) {
            return
        }

        let selected = $output_lines | first | str trim
        if ($selected | is-empty) {
            return
        }

        let fields = $selected | split row $delimiter
        let kind = $fields.0
        let project = $fields.1
        let path = $fields.2

        if ($env.HERDR_ENV? | default "") != "1" {
            print -e "Worktree actions require a Herdr-managed pane."
            return
        }

        # The Claude wrapper suppresses trust prompts. For new repositories,
        # manually set projects[<root>].hasTrustDialogAccepted=true in
        # ~/.config/claude/.claude.json; trust repository roots, not worktrees.
        if $kind == "worktree" {
            ^herdr worktree open --cwd $project --path $path --focus | ignore
            return
        }

        let path = (__new-worktree-path $project)
        ^herdr worktree create --cwd $project --path $path --focus | ignore
        return
    } catch {
        print "No project directory found."
    }
}
