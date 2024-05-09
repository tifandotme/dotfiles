# this file does not get loaded in nushell config, instead invoked by helix keymap
let tmp = (mktemp -t "yazi-picker.XXXXXX")
yazi --chooser-file $tmp

let content = open $tmp | str replace --all (char newline) ' ' | str trim
if $content != "" {
  zellij action toggle-floating-panes
  zellij action write 27 # send <Escape> key
  zellij action write-chars $":open ($content)"
  zellij action write 13 # send <Enter> key
  zellij action toggle-floating-panes
}

zellij action close-pane
