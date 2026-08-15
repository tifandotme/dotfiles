def __project-dirs [] {
    mut project_dirs = []
    let projects_dir = $env.XDG_PROJECTS_DIR? | default ($env.HOME | path join 'projects')

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
        worktrees: ($worktrees | where path != $project)
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

def __format-session-time [value] {
    try {
        $value | into datetime | date humanize
    } catch { "unknown" }
}

def __preview-sessions [path: string, branch: string] {
    let reset = (ansi reset)
    let label = (ansi cyan_bold)
    let muted = (ansi dark_gray_dimmed)
    let sessions_root = (
        $env.PI_AGENT_DIR?
        | default (
            $env.PI_CODING_AGENT_DIR?
            | default ($env.HOME | path join ".config" "pi")
            | path join "sessions"
        )
        | path expand
    )
    let claude_root = (
        $env.CLAUDE_CONFIG_DIR?
        | default ($env.HOME | path join ".config" "claude")
        | path expand
    )
    let pi_path_key = $path | str replace --all "/" "-"
    let claude_path_key = $path | str replace --all "/" "-" | str replace --all "." "-"
    let pi_dir = $sessions_root | path join $"-($pi_path_key)--"
    let claude_dir = $claude_root | path join "projects" $claude_path_key
    mut sessions = []

    let pi_files = (glob $"($pi_dir)/*.jsonl")
    if ($pi_files | is-not-empty) {
        for info in (try { ls ...$pi_files } catch { [] }) {
            let header = (
                try {
                    open $info.name
                    | lines
                    | first
                    | from json
                } catch { null }
            )
            if $header == null or (try { $header.type } catch { "" }) != "session" {
                continue
            }
            if (try { $header.cwd } catch { "" }) != $path {
                continue
            }
            let file_name = $info.name | path basename | str replace ".jsonl" ""
            let session_id = (
                try { $header.id } catch {
                    $file_name | split row "_" | last
                }
            )
            let short_id = $session_id | str substring 0..7
            let title = (
                try { $header.name } catch { $"Pi session ($short_id)" }
            )
            let title = if ($title | is-empty) { $"Pi session ($short_id)" } else { $title }
            let session = {
                agent: "pi"
                title: $title
                last_active: (__format-session-time $info.modified)
                sort_key: $info.modified
                branch: $branch
                size: $info.size
            }
            $sessions = ($sessions | append $session)
        }
    }

    let claude_files = (glob $"($claude_dir)/*.jsonl")
    if ($claude_files | is-not-empty) {
        for info in (try { ls ...$claude_files } catch { [] }) {
            let entries = (
                try {
                    open $info.name
                    | lines
                    | each {|line| try { $line | from json } catch { null } }
                } catch { [] }
            )
            let cwd_record = (
                $entries
                | where {|entry| (try { $entry.cwd } catch { "" }) == $path }
                | first
            )
            if $cwd_record == null {
                continue
            }
            let session_id = (
                try { $cwd_record.sessionId } catch {
                    $info.name | path basename | str replace ".jsonl" ""
                }
            )
            let short_id = $session_id | str substring 0..7
            let title_record = (
                $entries
                | where {|entry| (try { $entry.type } catch { "" }) == "custom-title" }
                | last
            )
            let title = (
                try { $title_record.customTitle } catch { $"Claude session ($short_id)" }
            )
            let title = if ($title | is-empty) { $"Claude session ($short_id)" } else { $title }
            let session_branch = (try { $cwd_record.gitBranch } catch { "" })
            let session_branch = if ($session_branch | is-empty) { $branch } else { $session_branch }
            let session = {
                agent: "Claude Code"
                title: $title
                last_active: (__format-session-time $info.modified)
                sort_key: $info.modified
                branch: $session_branch
                size: $info.size
            }
            $sessions = ($sessions | append $session)
        }
    }

    print ""
    if ($sessions | is-empty) {
        print $"($label)Sessions:($reset) ($muted)none($reset)"
        return
    }

    let session_count = $sessions | length
    print $"($label)Sessions:($reset) ($session_count)"
    for session in ($sessions | sort-by sort_key | reverse) {
        print $"  ($session.title)"
        print $"    ($session.last_active) • ($session.branch) • ($session.size) • ($session.agent)"
    }
}

def __preview-prs [path: string, branch: string] {
    let reset = (ansi reset)
    let label = (ansi cyan_bold)
    let green = (ansi green_bold)
    let cyan = (ansi cyan_bold)
    let red = (ansi red_dimmed)
    let yellow = (ansi yellow_bold)
    let muted = (ansi dark_gray_dimmed)
    let cache_root = (
        $env.XDG_CACHE_HOME?
        | default ($env.HOME | path join ".cache")
        | path join "nushell" "project-prs"
    )
    let cache_key = [$path $branch] | str join "\n" | hash sha256
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
            ^gh pr list --head $branch --state all --limit 30 --json number,title,state,isDraft,baseRefName,statusCheckRollup
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
        print $"#($pr.number)  ($state_color)($pr.state)($reset)  -> ($pr.baseRefName)($draft)"
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
    print $"($label)Type:($reset) ($kind)"
    print $"($label)Branch:($reset) ($branch)"
    print $"($label)Path:($reset) ($path)"
    let action = if $kind == "worktree" {
        "Enter opens/focuses"
    } else {
        "Enter creates and focuses"
    }
    print $"($label)Herdr:($reset) ($action)"
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

    __preview-sessions $path $branch

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

def __new-worktree-branch [] {
    loop {
        let branch = input "New branch name: " | str trim
        if ($branch | is-empty) {
            print -e "Branch name cannot be empty."
            continue
        }
        if ($branch | str contains " ") {
            print -e "Branch name cannot contain spaces."
            continue
        }
        return $branch
    }
}

export def --env open-project [default_project: string = ""] {
    try {
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
                        "<new branch>"
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

        if ($rows | is-empty) {
            print "No Git projects found."
            return
        }

        let delimiter = (char tab)
        let preview = "FZF_KIND={1} FZF_PATH={3} FZF_BRANCH={4} nu -c 'source ~/.config/nushell/scripts/project.nu; __worktree-preview $env.FZF_KIND $env.FZF_PATH $env.FZF_BRANCH'"
        mut fzf_args = [
            "--ansi"
            "--delimiter" $delimiter
            "--with-nth" "5"
            "--no-sort"
            "--layout" "reverse-list"
            "--prompt" "worktree> "
            "--header"
            "Enter open/focus  •  select a project to create a worktree  •  Esc cancel"
            "--header-first"
            "--color"
            "fg:-1,bg:-1,fg+:-1,bg+:-1,hl:cyan,hl+:cyan,pointer:magenta,prompt:cyan,header:yellow,marker:green"
            "--preview" $preview
            "--preview-window" "right:45%"
            "--preview-label" " details "
        ]
        if ($default_project | is-not-empty) {
            $fzf_args = ($fzf_args | append $"--query=($default_project)")
        }

        let selected = (
            $rows
            | str join "\n"
            | ^fzf ...$fzf_args
            | str trim
        )
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

        if $kind == "worktree" {
            ^herdr worktree open --cwd $project --path $path --focus | ignore
            return
        }

        let branch = (__new-worktree-branch)
        ^herdr worktree create --cwd $project --branch $branch --focus | ignore
    } catch {
        print "No project directory found."
    }
}
