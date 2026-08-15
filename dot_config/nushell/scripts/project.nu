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
        let preview = "printf 'Type: %s\\nBranch: %s\\nPath: %s\\nHerdr: Enter opens/focuses\\n\\n' {1} {4} {3}; git -C {3} status --short"
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
