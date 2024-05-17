# this file does not get loaded in nushell config, instead invoked by helix keymap
let tmp = (mktemp -t "yazi-picker.XXXXXX")
yazi --chooser-file $tmp

let content = open $tmp | str replace --all (char newline) ' ' | str trim
if $content != "" {
  ^(mise which zellij) action toggle-floating-panes
  ^(mise which zellij) action write 27 # send <Escape> key
  ^(mise which zellij) action write-chars $":open ($content)"
  ^(mise which zellij) action write 13 # send <Enter> key
  ^(mise which zellij) action toggle-floating-panes
}

^(mise which zellij) action close-pane
