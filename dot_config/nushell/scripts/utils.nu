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
