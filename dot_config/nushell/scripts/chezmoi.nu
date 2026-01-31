# Add non-template managed files to chezmoi and push to git (test)
export def sync [] {
  try {
    chezmoi re-add
    chezmoi status
    chezmoi git add .
    chezmoi git -- commit -m "update"
    chezmoi git push
  } catch {
    print "hiya."
  }
}
