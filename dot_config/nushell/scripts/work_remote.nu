const zero_oid = "0000000000000000000000000000000000000000"
const schema_version = 1

# work-remote keeps remote work explicit: local state is queued first, remote
# changes run later after a fresh validation and one human confirmation.

def fail [message: string, code: int = 1] {
    print -e $message
    exit $code
}

def state-root [] {
    let state_home = $env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state")
    $state_home | path join "work-remote"
}

def pending-root [] {
    state-root | path join "pending"
}
def done-root [] {
    state-root | path join "done"
}
def lock-root [] {
    state-root | path join "run.lock"
}

def ensure-state [] {
    let root = state-root
    mkdir $root
    mkdir (pending-root)
    mkdir (done-root)
    ^chmod 700 $root
    ^chmod 700 (pending-root)
    ^chmod 700 (done-root)
}

def canonical [value: string] {
    $value | path expand
}

def current-date [] {
    let override = $env.WORK_REMOTE_NOW? | default ""
    if ($override | is-empty) {
        date now
    } else {
        try {
            $override | into datetime
        } catch {
            fail $'Invalid WORK_REMOTE_NOW: ($override)'
        }
    }
}

def is-weekend [] {
    match (current-date | format date "%u") {
        "6" | "7" => true
        _ => false
    }
}

def weekend-override [] {
    ($env.WORK_REMOTE_ALLOW_WEEKEND? | default "") == "1"
}

def assert-oid [value: string, label: string] {
    if not ($value =~ '^[0-9a-f]{40}$') {
        fail $'Invalid ($label): ($value)'
    }
}

def assert-ref [value: string, label: string] {
    if not ($value =~ '^refs/heads/[A-Za-z0-9._/-]+$') {
        fail $'Unsupported ($label): ($value)'
    }
}

def assert-remote-name [value: string] {
    if not ($value =~ '^[A-Za-z0-9._-]+$') {
        fail $'Invalid remote name: ($value)'
    }
}

def assert-branch [value: string] {
    if not ($value =~ '^[A-Za-z0-9._/-]+$') {
        fail $'Invalid branch name: ($value)'
    }
}

def git-common-dir [repo_root: string] {
    let result = (
        ^git -C $repo_root rev-parse --path-format=absolute --git-common-dir
        | complete
    )
    if $result.exit_code != 0 {
        error make {msg: $'Not a Git repository: ($repo_root)'}
    }
    canonical ($result.stdout | str trim)
}

def repository-root [repo_root: string] {
    let common_dir = git-common-dir $repo_root
    $common_dir | path dirname
}

def is-work-repo [repo_root: string] {
    let root = (canonical $repo_root)
    let work_root = canonical ($nu.home-dir | path join "projects" "work")
    ($root == $work_root) or ($root | str starts-with $'($work_root)/')
}

def require-work-repo [repo_root: string] {
    let root = (try {
        repository-root $repo_root
    } catch {|error|
        fail $error.msg
    })
    if not (is-work-repo $root) {
        fail $'Not a work repository: ($root)'
    }
    $root
}

def git-remote-url [repo_root: string, remote: string] {
    let result = (^git -C $repo_root remote get-url $remote | complete)
    if $result.exit_code != 0 {
        fail $'Cannot read remote URL for ($remote): ($result.stderr | str trim)'
    }
    $result.stdout | str trim
}

def remote-oid [repo_root: string, remote: string, remote_ref: string] {
    let result = (^git -C $repo_root ls-remote $remote $remote_ref | complete)
    if $result.exit_code != 0 {
        fail $'Cannot inspect remote branch: ($result.stderr | str trim)'
    }
    let line = $result.stdout | lines | first
    if $line == null {
        $zero_oid
    } else {
        $line | split row "\t" | first | str trim
    }
}

def local-oid [repo_root: string, local_ref: string] {
    let result = (^git -C $repo_root rev-parse --verify --end-of-options $local_ref | complete)
    if $result.exit_code != 0 {
        fail $'Cannot inspect local ref ($local_ref): ($result.stderr | str trim)'
    }
    $result.stdout | str trim
}

def diff-hash [repo_root: string, base_oid: string, head_oid: string] {
    let result = (
        ^git -C $repo_root diff --no-ext-diff $'($base_oid)...($head_oid)'
        | complete
    )
    if $result.exit_code != 0 {
        fail $'Cannot calculate the approved diff hash: ($result.stderr | str trim)'
    }
    $result.stdout | hash sha256 | str trim
}

def read-file [path: string, label: string] {
    if not ($path | path exists) {
        fail $'Missing ($label): ($path)'
    }
    open --raw $path
}

def atomic-save [value, destination: string] {
    let temporary = $'($destination).tmp-(random uuid)'
    try {
        $value | to json --indent 2 | save --force $temporary
        ^chmod 600 $temporary
        mv -f $temporary $destination
    } catch {|error|
        if ($temporary | path exists) { rm -f $temporary }
        error make {msg: $'Cannot write task file: ($error.msg)'}
    }
}

def task-files [root: string] {
    let files = (glob $'($root)/*.json')
    $files | sort
}

def load-task [path: string] {
    try {
        let task = open --raw $path | from json
        $task | upsert file $path
    } catch {|error| fail $'Invalid task file ($path): ($error.msg)' }
}

def load-pending [] {
    ensure-state
    task-files (pending-root) | each {|path| load-task $path}
}

def task-summary [task] {
    {
        id: $task.id
        action: $task.action
        repository: $task.repo_root
        branch: $task.branch
        head: $task.head_oid
        title: ($task.title? | default "")
        created: $task.created_at
    }
}

def print-pending [] {
    let tasks = (load-pending)
    if ($tasks | is-empty) {
        print "No pending work-remote tasks."
    } else {
        $tasks | each {|task| task-summary $task} | print
    }
    $tasks
}

def task-id-for [task] {
    let key = $'($task.action)|($task.repo_root)|($task.remote_ref)|($task.head_oid)'
    $key | hash sha256 | str substring 0..15
}

def find-duplicate [task] {
    let key = (task-id-for $task)
    load-pending | where {|existing| (task-id-for $existing) == $key} | first
}

def enqueue-task [task] {
    ensure-state
    let duplicate = (find-duplicate $task)
    if $duplicate != null {
        print $'Already queued: ($duplicate.id)'
        return $duplicate.id
    }
    let id = (random uuid)
    let full_task = (
        $task
        | upsert schema $schema_version
        | upsert id $id
        | upsert created_at (current-date | format date "%+")
    )
    let destination = pending-root | path join $'($id).json'
    atomic-save $full_task $destination
    print $'Queued ($full_task.action) task ($id)'
    $id
}

def validate-common-task [task] {
    if ($task.schema? | default 0) != $schema_version {
        fail $'Unsupported task schema in ($task.file)'
    }
    let repo_root = (require-work-repo $task.repo_root)
    let expected_common = (canonical $task.common_dir)
    let actual_common = (git-common-dir $repo_root)
    if $actual_common != $expected_common {
        fail $'Repository identity changed: expected ($expected_common), got ($actual_common)'
    }
    assert-remote-name $task.remote
    let actual_url = (git-remote-url $repo_root $task.remote)
    if $actual_url != $task.remote_url {
        fail $'Remote identity changed: expected ($task.remote_url), got ($actual_url)'
    }
    assert-ref $task.local_ref "local ref"
    assert-ref $task.remote_ref "remote ref"
    assert-oid $task.head_oid "expected HEAD"
    assert-oid $task.expected_remote_oid "expected remote OID"
    let actual_head = (local-oid $repo_root $task.local_ref)
    if $actual_head != $task.head_oid {
        fail $'HEAD changed for task ($task.id): expected ($task.head_oid), got ($actual_head)'
    }
    let actual_remote = (remote-oid $repo_root $task.remote $task.remote_ref)
    if ($actual_remote != $task.expected_remote_oid) and ($actual_remote != $task.head_oid) {
        fail $'Remote branch changed for task ($task.id): expected ($task.expected_remote_oid) or ($task.head_oid), got ($actual_remote)'
    }
    {repo_root: $repo_root, actual_head: $actual_head, actual_remote: $actual_remote}
}

def validate-pr-task [task] {
    let common = (validate-common-task $task)
    assert-branch $task.branch
    if $task.local_ref != $'refs/heads/($task.branch)' {
        fail $'PR task local ref does not match branch: ($task.local_ref)'
    }
    if $task.remote_ref != $'refs/heads/($task.branch)' {
        fail $'PR task remote ref does not match branch: ($task.remote_ref)'
    }
    if not ($task.base =~ '^[A-Za-z0-9._/-]+$') {
        fail $'Invalid base branch: ($task.base)'
    }
    assert-oid $task.base_oid "base OID"
    if not ($task.diff_hash =~ '^[0-9a-f]{64}$') {
        fail $'Invalid diff hash: ($task.diff_hash)'
    }
    if ($task.title | str trim | is-empty) or ($task.body | str trim | is-empty) {
        fail $'PR task ($task.id) has empty title or body'
    }
    let actual_base = (remote-oid $common.repo_root $task.remote $'refs/heads/($task.base)')
    if $actual_base != $task.base_oid {
        fail $'Base branch changed for task ($task.id): expected ($task.base_oid), got ($actual_base)'
    }
    let actual_diff = (diff-hash $common.repo_root $task.base_oid $common.actual_head)
    if $actual_diff != $task.diff_hash {
        fail $'Approved diff changed for task ($task.id): expected ($task.diff_hash), got ($actual_diff)'
    }
    $common
}

def existing-pr [task] {
    let result = (
        ^gh pr list --repo $task.repo_slug --head $task.branch --base $task.base --state open --json number,url,headRefName,baseRefName,headRefOid,baseRefOid
        | complete
    )
    if $result.exit_code != 0 {
        fail $'Cannot inspect existing PRs: ($result.stderr | str trim)'
    }
    let prs = $result.stdout | from json
    $prs | where {|pr| ($pr.headRefName == $task.branch) and ($pr.baseRefName == $task.base) and ($pr.headRefOid == $task.head_oid) and ($pr.baseRefOid == $task.base_oid)} | first
}

def run-push [task] {
    let common = (validate-common-task $task)
    if $common.actual_remote == $task.head_oid {
        print $'Already pushed ($task.branch)'
        return
    }
    let result = (
        ^git -C $common.repo_root push $task.remote $'($task.local_ref):($task.remote_ref)'
        | complete
    )
    if $result.exit_code != 0 {
        fail $'Push failed for task ($task.id): ($result.stderr | str trim)'
    }
    print $'Pushed ($task.branch)'
}

def run-pr [task] {
    let common = (validate-pr-task $task)
    let existing = (existing-pr $task)
    if $existing != null {
        print $'PR already exists: ($existing.url)'
        return {url: $existing.url, status: "already-exists"}
    }
    if $common.actual_remote != $task.head_oid {
        let push_result = (
            ^git -C $common.repo_root push $task.remote $'($task.local_ref):($task.remote_ref)'
            | complete
        )
        if $push_result.exit_code != 0 {
            fail $'Push failed for PR task ($task.id): ($push_result.stderr | str trim)'
        }
    }
    let pr_result = (
        ^gh pr create --repo $task.repo_slug --title $task.title --body $task.body --base $task.base --head $task.branch
        | complete
    )
    if $pr_result.exit_code != 0 {
        fail $'PR creation failed for task ($task.id): ($pr_result.stderr | str trim)'
    }
    print $'Created PR: ($pr_result.stdout | str trim)'
    {
        url: ($pr_result.stdout | str trim)
        status: "created"
    }
}

def archive-task [task, result] {
    let archived = (
        $task
        | reject file
        | upsert completed_at (current-date | format date "%+")
        | upsert result $result
    )
    let destination = done-root | path join $'($task.id).json'
    atomic-save $archived $destination
    rm -f $task.file
}

def acquire-lock [] {
    let lock = lock-root
    try {
        mkdir $lock
    } catch {
        fail $'Another work-remote runner owns the lock: ($lock)'
    }
    ^chmod 700 $lock
    $lock
}

def run-tasks [selected: list<string>] {
    let auto_confirm = $selected | any {|value| $value == "--yes"}
    let selected = $selected | where {|value| $value != "--yes"}
    if (is-weekend) and not (weekend-override) {
        fail "Queue execution is disabled on Saturday and Sunday."
    }
    let tasks = (
        load-pending
        | where {|task| ($selected | is-empty) or ($selected | any {|id| $id == $task.id})}
    )
    if ($tasks | is-empty) {
        if ($selected | is-empty) {
            print "No pending work-remote tasks."
        } else {
            fail $'No matching pending task: ($selected | str join ", ")'
        }
        return
    }
    print ($tasks | each {|task| task-summary $task})
    if not $auto_confirm {
        let answer = (input "Execute these tasks? Type RUN to continue: ")
        if ($answer | str trim) != "RUN" {
            print "Cancelled."
            return
        }
    }
    let lock = (acquire-lock)
    try {
        for task in $tasks {
            let result = (try {
                match $task.action {
                    "push" => { run-push $task; {status: "pushed"} }
                    "pr" => (run-pr $task)
                    _ => (fail $'Unsupported task action: ($task.action)')
                }
            } catch {|error|
                print -e $'Task ($task.id) failed: ($error.msg)'
                exit 1
            })
            archive-task $task $result
        }
        print $'Completed ($tasks | length) tasks.'
    } finally {
        rm -rf $lock
    }
}

def enqueue-push [args: list<string>] {
    if ($args | length) != 8 {
        fail "Invalid enqueue-push arguments." 2
    }
    let repo_root = (require-work-repo $args.0)
    let remote = $args.1
    let remote_url = $args.2
    let local_ref = $args.3
    let head_oid = $args.4
    let remote_ref = $args.5
    let expected_remote_oid = $args.6
    let source = $args.7
    assert-remote-name $remote
    assert-ref $local_ref "local ref"
    assert-ref $remote_ref "remote ref"
    assert-oid $head_oid "HEAD"
    assert-oid $expected_remote_oid "remote OID"
    if $source != "hook" {
        fail "Push tasks can only be queued by the pre-push hook."
    }
    enqueue-task {
        action: "push"
        repo_root: $repo_root
        common_dir: (git-common-dir $repo_root)
        remote: $remote
        remote_url: $remote_url
        local_ref: $local_ref
        remote_ref: $remote_ref
        head_oid: $head_oid
        expected_remote_oid: $expected_remote_oid
        branch: ($local_ref | str replace --regex '^refs/heads/' '')
    }
}

def queue-pr-task [repo_root: string, repo_slug: string, branch: string, base: string, title: string, body: string] {
    let remote = "origin"
    let local_ref = $'refs/heads/($branch)'
    let remote_ref = $local_ref
    let head_oid = local-oid $repo_root $local_ref
    let expected_remote_oid = remote-oid $repo_root $remote $remote_ref
    let base_oid = remote-oid $repo_root $remote $'refs/heads/($base)'
    let diff_hash_value = diff-hash $repo_root $base_oid $head_oid
    let remote_url = git-remote-url $repo_root $remote
    assert-remote-name $remote
    assert-ref $local_ref "local ref"
    assert-ref $remote_ref "remote ref"
    assert-oid $head_oid "HEAD"
    assert-oid $expected_remote_oid "remote OID"
    assert-oid $base_oid "base OID"
    assert-branch $branch
    if ($title | str trim | is-empty) or ($body | str trim | is-empty) {
        fail "PR title and body cannot be empty."
    }
    if not ($repo_slug =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        fail $'Invalid GitHub repository: ($repo_slug)'
    }
    enqueue-task {
        action: "pr"
        repo_root: $repo_root
        common_dir: (git-common-dir $repo_root)
        remote: $remote
        remote_url: $remote_url
        repo_slug: $repo_slug
        local_ref: $local_ref
        remote_ref: $remote_ref
        head_oid: $head_oid
        expected_remote_oid: $expected_remote_oid
        branch: $branch
        base: $base
        base_oid: $base_oid
        diff_hash: $diff_hash_value
        title: ($title | str trim)
        body: ($body | str trim)
    }
}

def gh-option-value [args: list<string>, index: int, option: string] {
    if $index >= (($args | length) - 1) {
        fail $'Missing value for ($option).'
    }
    $args | get ($index + 1)
}

def parse-gh-pr-create [args: list<string>] {
    mut parsed = {
        repo: ""
        title: ""
        body: ""
        base: ""
        head: ""
    }
    mut index = 0
    while $index < ($args | length) {
        let arg = $args | get $index
        match $arg {
            "pr" | "create" => { $index += 1 }
            "--repo" => {
                $parsed = $parsed | upsert repo (gh-option-value $args $index $arg)
                $index += 2
            }
            "--title" => {
                $parsed = $parsed | upsert title (gh-option-value $args $index $arg)
                $index += 2
            }
            "--body-file" => {
                let path = gh-option-value $args $index $arg
                if $path == "-" {
                    fail "Weekend PRs require a body file."
                }
                $parsed = $parsed | upsert body (read-file $path "PR body file" | str trim)
                $index += 2
            }
            "--base" => {
                $parsed = $parsed | upsert base (gh-option-value $args $index $arg)
                $index += 2
            }
            "--head" => {
                $parsed = $parsed | upsert head (gh-option-value $args $index $arg)
                $index += 2
            }
            _ => {
                fail $'Weekend PRs require --repo, --title, --body-file, --base, and --head. Unsupported option: ($arg)'
            }
        }
    }
    for field in [repo title body base head] {
        let value = $parsed | get $field | str trim
        if ($value | is-empty) {
            fail $'Weekend PRs require --($field).'
        }
    }
    $parsed
}

def queue-pr-from-gh [args: list<string>] {
    if (gh-pr-command $args) != "create" {
        exit 75
    }
    if (not (is-weekend)) or (weekend-override) {
        exit 75
    }
    let repo_root = (try {
        repository-root (pwd)
    } catch {
        exit 75
    })
    if not (is-work-repo $repo_root) {
        exit 75
    }
    let parsed = parse-gh-pr-create $args
    queue-pr-task $repo_root $parsed.repo $parsed.head $parsed.base $parsed.title $parsed.body
}

def hook-pre-push [args: list<string>] {
    if ($args | length) != 2 {
        fail "pre-push requires a remote name and URL" 2
    }
    if (not (is-weekend)) or (weekend-override) {
        return
    }
    let remote = $args.0
    let remote_url = $args.1
    let lines = open --raw /dev/stdin | lines
    if ($lines | length) != 1 {
        print -e "Blocked unsupported weekend push: expected one branch update."
        exit 1
    }
    let fields = $lines.0 | split row " " | where {|field| $field | is-not-empty}
    if ($fields | length) != 4 {
        print -e "Blocked unsupported weekend push: malformed ref update."
        exit 1
    }
    let local_ref = $fields.0
    let local_oid = $fields.1
    let remote_ref = $fields.2
    let remote_oid = $fields.3
    if not (($local_ref | str starts-with "refs/heads/") and ($remote_ref | str starts-with "refs/heads/")) {
        print -e "Blocked unsupported weekend push: only one branch update is queueable."
        exit 1
    }
    let repo_root = (repository-root (pwd))
    if not (is-work-repo $repo_root) {
        return
    }
    enqueue-push [
        $repo_root
        $remote
        $remote_url
        $local_ref
        $local_oid
        $remote_ref
        $remote_oid
        "hook"
    ] | ignore
    print -e "Weekend push queued. No remote change was made."
    exit 1
}

def gh-pr-command [args: list<string>] {
    let pr_index = (
        $args
        | enumerate
        | where {|item| $item.item == "pr"}
        | get index
        | first
    )
    if ($pr_index == null) or ($pr_index == (($args | length) - 1)) {
        ""
    } else {
        $args | get ($pr_index + 1)
    }
}

def pr-write [args: list<string>] {
    (gh-pr-command $args) in [
        "create"
        "edit"
        "comment"
        "review"
        "merge"
        "close"
        "reopen"
    ]
}

def current-work-repo [] {
    try {
        is-work-repo (repository-root (pwd))
    } catch {
        false
    }
}

def guard-gh [args: list<string>] {
    if (is-weekend) and not (weekend-override) and (pr-write $args) and (current-work-repo) {
        print -e "Blocked weekend GitHub PR mutation."
        exit 1
    }
    true
}

def install-hooks [] {
    ensure-state
    let work_root = canonical ($nu.home-dir | path join "projects" "work")
    let central_hook_root = canonical ($nu.home-dir | path join ".config" "git" "hooks" "work")
    let repos = (
        glob $'($work_root)/*'
        | where {|path| (($path | path join ".git") | path exists)}
    )
    if ($repos | is-empty) {
        print "No work repositories found."
        return
    }
    for repo in $repos {
        let repo_root = (repository-root $repo)
        let common_dir = (git-common-dir $repo_root)
        let configured_result = (^git -C $repo_root config --local --get core.hooksPath | complete)
        let configured = if $configured_result.exit_code == 0 {
            $configured_result.stdout | str trim
        } else { "" }
        let saved_result = (
            ^git -C $repo_root config --local --get work-remote.originalHook
            | complete
        )
        let saved_original = if $saved_result.exit_code == 0 {
            $saved_result.stdout | str trim
        } else { "" }
        let original = if ($saved_original | is-not-empty) {
            $saved_original
        } else if ($configured | is-empty) or ($configured == $central_hook_root) {
            $common_dir | path join "hooks" "pre-push"
        } else if ($configured | str starts-with "/") {
            $configured | path join "pre-push"
        } else {
            $repo_root | path join $configured "pre-push"
        }
        ^git -C $repo_root config --local work-remote.originalHook $original
        ^git -C $repo_root config --local core.hooksPath $central_hook_root
        print $'Installed hook for ($repo_root), preserving ($original)'
    }
}

# Show the work-remote command and its public subcommands.
export def "work-remote" [] {
    help "work-remote"
}

# List pending remote work.
export def "work-remote list" [] {
    print-pending | ignore
}

# Execute pending remote work after validation and confirmation.
export def "work-remote run" [
    task_id?: string # Run only this task.
    --yes(-y) # Skip confirmation.
] {
    let run_args = if $task_id == null { [] } else { [$task_id] }
    let run_args = if $yes {
        $run_args | append "--yes"
    } else { $run_args }
    run-tasks $run_args
}

def work-remote-main [command?: string, --yes(-y), ...args: string] {
    match ($command | default "") {
        "" | "--help" | "-h" => { help "work-remote" }
        "help" => {
            let topic = if ($args | is-empty) {
                "work-remote"
            } else {
                $'work-remote ($args.0)'
            }
            help $topic
        }
        "list" => { work-remote list }
        "run" => {
            let run_args = if $yes {
                $args | append "--yes"
            } else { $args }
            run-tasks $run_args
        }
        "queue-pr-from-gh" => { queue-pr-from-gh $args | ignore }
        "enqueue-push" => {
            enqueue-push $args | ignore
        }
        "hook-pre-push" => { hook-pre-push $args }
        "guard-gh" => {
            guard-gh $args | ignore
        }
        "install-hooks" => { install-hooks }
        _ => { fail $'Unknown work-remote command: ($command)' 2 }
    }
}
