# Rebase to latest upstream release tag
export def "rebase-release" [remote = "upstream"] {
  print "Fetching tags..."
  git fetch $remote --tags

  let latest_tag = (git describe --tags --abbrev=0 $"($remote)/HEAD" | str trim)

  if ($latest_tag | is-empty) {
    print "No tags found on upstream."
    return
  }

  print $"Rebasing to latest release: ($latest_tag)"
  git rebase $latest_tag
}

# Log since last release
export def "loggy" [] {
  git log --oneline (git describe --tags --abbrev=0 upstream/HEAD)
}

# Delete release + tag (local and remote)
export def "revert-release" [tag: string] {
  gh release delete $tag -y
  git push origin --delete $tag
  git tag -d $tag
}
