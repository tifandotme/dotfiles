# Show all open ports
def open-ports [] {
  lsof -i -P -n | grep LISTEN
}

# List all custom commands and aliases (filtered by noteworthiness)
def commands [] {
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

  help commands | where command_type =~ 'custom|alias' | reject params input_output search_terms category command_type | where name !~ ($custom_excludes | str join "|") | sort-by description
}

# Setup project environment
def revert-release [tag: string] {
  gh release delete $tag -y
  git push origin --delete $tag
  git tag -d $tag
}

# Setup project environment
def open-project [default_project: string = ""] {
  # If the default project is present in the project list, fzf will pre-select it using --query.
  # This makes it easy to open your most-used project by just hitting Enter.
  # const default_project = "aquasense-app"
  try {
    let project_dirs = _ls ~/personal ~/work | where type =~ dir | get name

    let project_list = $project_dirs | str join "\n" | str replace --all $"($env.HOME)/" '' | str join "\n"

    let has_default = $project_list | str contains $default_project

    let chosen_project = if $has_default {
      $project_list | fzf --query=($default_project)
    } else {
      $project_list | fzf
    }

    let dir_name = $chosen_project | split row "/" | get 1
    let absolute_path = $"($env.HOME)/($chosen_project)"

    let last_tab_index = zellij action query-tab-names | split row "\n" | length
    zellij action go-to-tab $last_tab_index

    zellij action new-tab --name $dir_name --cwd $absolute_path

    zellij action new-tab --name $"($dir_name)\(git\)"
    zellij run --close-on-exit --cwd $absolute_path -- nu -c lazygit
    zellij action focus-previous-pane; zellij action close-pane

    zellij action go-to-previous-tab
  } catch {
    print "No project directory found."
  }
}

# Open actions-runner tab and run script
def open-actions-runner [] {
  let response = input $"(ansi yellow)Do you want to open the actions-runner? \(Y/n\): (ansi reset)" | str downcase
  let include_runner = $response == "y" or $response == ""

  if $include_runner == false {
    return
  }

  let absolute_path = $env.HOME | path join "work/actions-runner"
  let dir_name = "runner (running)"

  let last_tab_index = zellij action query-tab-names | split row "\n" | length
  zellij action go-to-tab $last_tab_index

  zellij action new-tab --name $dir_name --cwd $absolute_path
  zellij run --close-on-exit --cwd $absolute_path -- nu -c "./run.sh"
  zellij action focus-previous-pane; zellij action close-pane

  zellij action go-to-previous-tab
}

def open-webui [] {
  let path = $env.HOME | path join personal openweb-ui
  docker compose up -f $path -d
}

# Open up a book
def open-book [] {
  try {
    let books_dir = $"($env.HOME)/personal/books/"

    let books = _ls ...(glob $"($books_dir)**/*.{pdf,epub}") | get name

    let chosen_book = $books | str join "\n" | str replace --all $books_dir '' | str join "\n" | fzf

    ^open $"($books_dir)($chosen_book)"
  } catch {
    print "No books found."
  }
}

# Diff two files located anywhere within the current directory (MUST be inside a git repository)
def compare [] {
  use std

  let is_git_repo = (do { git rev-parse --is-inside-work-tree } | complete).exit_code == 0

  let files = if $is_git_repo {
    # If in git repo, use git ls-files for untracked and tracked, excluding .gitignore
    do {
      git ls-files --others --exclude-standard --cached
    } | complete | if $in.exit_code == 0 { $in.stdout } else { "" }
  } else {
    # Otherwise, get all files recursively
    _ls **/* | where type == file | get name | str join "\n"
  }

  if ($files | is-empty) {
    print "No files found in the current directory."
    return
  }

  try {
    let file_1 = $files | fzf --header="Choose a file"
    let file_2 = $files
    | split row "\n"
    | where {|x| $x != $file_1 }
    | str join "\n"
    | fzf --header="Choose another file to diff"

    difft $file_1 $file_2 --syntax-highlight="off"
  } catch {
    print "Failed to select files for diff."
  }
}

def open-firecrawl [] {
  let absolute_path = $env.HOME | path join personal firecrawl
  let tab_name = "firecrawl (running)"

  let existing_tabs = zellij action query-tab-names | split row "\n"
  if $tab_name in $existing_tabs {
    zellij action go-to-tab-name $tab_name
    return
  }

  let cmd = "if (colima status --json | from json | is-empty) { colima start }; if not (docker compose ps | str contains 'Up') { docker compose up -d }; lazydocker"

  zellij action new-tab --name $tab_name
  zellij run --close-on-exit --cwd $absolute_path -- nu -c $cmd
  zellij action focus-previous-pane; zellij action close-pane
}

alias _yt-dlp = yt-dlp
alias yt-dlp = yt-dlp --extractor-args="youtube:player_client=all" --embed-metadata --embed-chapters --embed-subs --embed-thumbnail --sponsorblock-remove="sponsor,selfpromo,interaction" --progress --quiet --output="%(uploader)s - %(title)s.%(ext)s"

# Download a YouTube video
def download-youtube [
  --audio (-a) # Download audio only
  --cwd # Save to current directory (default: ~/Downloads)
  url: string # URL of the thing
] {
  mut download_path = $env.HOME | path join "Downloads"
  if $cwd {
    $download_path = $env.PWD
  }

  print $"Download is starting and will be saved in ($download_path)\n"

  if $audio {
    yt-dlp --paths $download_path -f 140 $url
  } else {
    yt-dlp --paths $download_path --format-sort="res:720,codec:avc:m4a" $url
  }

  if $env.LAST_EXIT_CODE == 0 {
    print "\nDownload successful"
  } else {
    print "\nDownload unsuccessful"
  }
}
alias yd = download-youtube

hide yt-dlp

# Activate gcloud configurations
def gcloud-config [] {
  let active_config = gcloud config configurations list --filter="is_active=true" --format="value(name)" --quiet | str trim
  let selected_line = gcloud config configurations list --format="table(name,properties.core.account,properties.core.project)" --quiet | lines | skip 1 | fzf --prompt=('Select gcloud config (current: ' + $active_config + '): ')

  if ($selected_line | is-not-empty) {
    let current_account = gcloud config get-value account --quiet | lines | last | str trim
    let selected = $selected_line | str trim | split row -r '\s+' | get 1
    gcloud config configurations activate $selected --quiet
    let new_account = gcloud config get-value account --quiet | lines | last | str trim
    let project = gcloud config get-value project --quiet | lines | last | str trim
    if $current_account == $new_account {
      gcloud auth application-default set-quota-project $project --quiet
    } else {
      print ""
      print $"(ansi yellow)Account changed. Run 'gcloud auth application-default login' if needed.(ansi reset)"
      print ""
      let response = input "Do you want to run 'gcloud auth application-default login'? (Y/n): " | str downcase
      let run_login = $response == "y" or $response == ""
      if $run_login {
        gcloud auth application-default login --quiet
      }
    }
  }
}

def get-app-id [app_name: string] {
  let app_id = (ps | where name =~ $app_name | get id)
  if $app_id == "" {
    print "No app found with name: $app_name"
    return
  }
  return $app_id
}

# Update the format.nu script from the GitHub repo
def update-format-nu [] {
  let repo_dir = $nu.default-config-dir | path join scripts topiary-nushell-repo
  cd $repo_dir
  git pull
  if $env.LAST_EXIT_CODE == 0 {
    print "format.nu updated successfully"
  } else {
    print "Failed to update format.nu"
  }
}

# Open memory graph image
def open-memory-graph [] {
  if (which dot | is-empty) {
    print "Graphviz not installed. Install with: brew install graphviz"
    return
  }
  let json = (docker run --rm -v my-memory:/data alpine cat /data/memory.json)
  let data = $json | lines | where {|line| $line != "" } | each {|line| $line | from json }
  let entities = $data | where type == "entity" | each {|e|
    let obs = $e.observations | each {|o| $o | str replace -r ": *" " " } | each {|o| $"- ($o)" } | str join "\n"
    $"\"($e.name)\" [label=\"($e.entityType)\n($obs)\" shape=box];"
  }
  let relations = $data | where type == "relation" | each {|r|
    $"\"($r.from)\" -> \"($r.to)\" [label=\"($r.relationType)\"];"
  }
  let dot = $"digraph G {\n($entities | append $relations | str join "\n")\n}"
  $dot | dot -Tpng -o /tmp/graph.png
  ^open /tmp/graph.png
}
