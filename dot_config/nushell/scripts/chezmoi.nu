# Add non-template managed files to chezmoi and push to git
export def sync [] {
  try {
    chezmoi re-add
    let diff_output = (chezmoi diff)
    if ($diff_output != "") {
      error make {msg: "chezmoi diff shows changes. Please update the file in template."}
    }
    chezmoi git add .
    chezmoi git -- commit -m "update"
    chezmoi git push
  } catch {|e|
    print "error: ($e.msg)"
  }
}
