export def compare [] {
  use std

  let is_git_repo = (do { git rev-parse --is-inside-work-tree } | complete).exit_code == 0

  let files = if $is_git_repo {
    do {
      git ls-files --others --exclude-standard --cached
    } | complete | if $in.exit_code == 0 { $in.stdout } else { "" }
  } else {
    _ls **/* | where type == file | get name | str join "\n"
  }

  if ($files | is-empty) {
    print "No files found in the current directory."
    return
  }

  try {
    let file_1 = $files | fzf --header="Choose a file"
    let file_2 = $files | split row "\n" | where {|x| $x != $file_1 } | str join "\n" | fzf --header="Choose another file to diff"
    difft $file_1 $file_2 --syntax-highlight="off"
  } catch {
    print "Failed to select files for diff."
  }
}

export def prep-excalidraw [
  file?: path
  --width: int = 500
] {
  let resize_arg = $"($width)>"

  let optimize = {|in_file|
    let parts = ($in_file | path parse)
    if ($parts.stem | str ends-with "_optimized") { return }

    let new_stem = $"($parts.stem)_optimized"
    let out_name = ($parts | update stem $new_stem | update extension "webp" | path join)

    magick $in_file -resize $resize_arg -strip -quality 75 $out_name

    if ($out_name | path exists) {
      rm $in_file
      print $"Converted: ($in_file) -> ($out_name)"
    } else {
      print -e $"Failed: ($in_file)"
    }
  }

  if ($file != null) {
    do $optimize $file
  } else {
    _ls | where name =~ '(?i)\.(jpg|jpeg|png|webp)$' | where name !~ '_optimized' | each {|row| do $optimize $row.name }
  }
}

export def --wrapped amp [...args] {
  EDITOR=vi _amp ...$args
}
