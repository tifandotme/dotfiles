# Add non-template managed files to chezmoi and push to git
export def sync [] {
  try {
    chezmoi re-add
    chezmoi status
    chezmoi git add .
    chezmoi git -- commit -m "update"
    chezmoi git push --force-with-lease
  } catch {
    print "hiya."
  }
}
