# Show all open ports
def open-ports [] {
    lsof -i -P -n | grep LISTEN
}

# List all custom commands and aliases (filtered by noteworthiness)
def commands [] {
    let custom_excludes = [
        "drop", "banner", "lsblk", "update terminal", "_", "main", "pwd", "show", "next", "add"
    ]

    help commands | where command_type =~ 'custom|alias' | reject params input_output search_terms category command_type | where name !~ ($custom_excludes | str join "|") | sort-by description
}

# Setup project environment
def open-project [] {
    try {
        let project_dirs = _ls ~/personal ~/work | where type =~ dir | get name

        # Prompt user to choose a project directory
        let chosen_project = $project_dirs | str join "\n" | str replace --all $"($env.HOME)/" '' | str join "\n" | fzf

        let dir_name = $chosen_project | split row "/" | get 1
        let absolute_path = $"($env.HOME)/($chosen_project)"

        let last_tab_index = zellij action query-tab-names | split row "\n" | length
        zellij action go-to-tab $last_tab_index

        zellij action new-tab --name $dir_name
        zellij action new-pane --cwd $absolute_path -- nu -i
        zellij action focus-previous-pane; zellij action close-pane

        zellij action new-tab --name $"($dir_name)\(git\)"
        zellij action new-pane --close-on-exit --cwd $absolute_path -- nu -i -c lazygit
        zellij action focus-previous-pane; zellij action close-pane

        zellij action go-to-previous-tab
    } catch {
        print "No project directory found."
    }
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

alias _yt-dlp = yt-dlp
alias yt-dlp = yt-dlp --extractor-args="youtube:player_client=all" --embed-metadata --embed-chapters --embed-subs --embed-thumbnail --sponsorblock-remove="sponsor,selfpromo,interaction" --progress --quiet --output="%(uploader)s - %(title)s.%(ext)s"

# Download a YouTube video
def download-youtube [
  --audio(-a) # Download audio only
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

# def get-app-id [app_name: string] {
#     let app_id = (ps | where name =~ $app_name | get id)
#     if $app_id == "" {
#         print "No app found with name: $app_name"
#         return
#     }
#     return $app_id
# }

# TODO keybinds
