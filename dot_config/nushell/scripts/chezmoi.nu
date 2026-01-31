# Add non-template managed files to chezmoi and push to git
export def sync [] {
  try {
    chezmoi re-add
    let output = (chezmoi status)
    if ($output != "") {
      chezmoi diff
      print ""
      chezmoi status
      print ""
      error make {msg: "Run `chezmoi edit --apply <file>` on each template first. Then re-run this command."}
    }
    chezmoi git add .
    chezmoi git -- commit -m "update"
    chezmoi git push
  } catch {|e|
    print $"error: ($e.msg)"
  }
}
