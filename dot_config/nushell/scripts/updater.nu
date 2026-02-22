# Start an update immediately
export def start [] {
  if (which brew | is-not-empty) {
    print $"(ansi green_bold)==>(ansi reset) Upgrading (ansi green)brew(ansi reset) packages"
    brew upgrade
  }

  if (which mise | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)mise(ansi reset) packages"
    mise upgrade --yes
  }

  if (which gh | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)gh(ansi reset) extensions"
    gh extension upgrade --all
  }

  if (which ya | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)yazi(ansi reset) packages"
    ya pkg upgrade

    # Yazi packages may modify package.toml - sync back to chezmoi
    if (which chezmoi | is-not-empty) {
      print $"\n(ansi green_bold)==>(ansi reset) Syncing (ansi green)yazi package.toml(ansi reset) to chezmoi"
      chezmoi add ~/.config/yazi/package.toml
    }
  }

  if (which bun | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)bun(ansi reset) global packages"

    # Pinned packages: name -> exact version to preserve
    let pinned = {
      "@sourcegraph/amp": "0.0.1771747379-gbb5ca2"
    }

    # Run update
    bun update --global --latest

    # Re-pin packages to locked versions after update
    $pinned | columns | each {|name|
      let version = $pinned | get $name
      print $"(ansi yellow)↺(ansi reset) Re-pinning ($name)@($version)"
      bun install -g $"($name)@($version)"
    }
  }

  if (which pnpm | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)pnpm(ansi reset) global packages"
    pnpm update --global --latest
  }

  if (which skills | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)skills(ansi reset) packages"
    skills update
  }
}

# Clean caches and uninstall unused packages (do this rarely)
export def clean [] {
  if (which mise | is-not-empty) {
    mise prune -y
    mise cache clear -y
  }
  if (which pnpm | is-not-empty) {
    pnpm store prune
  }
  if (which brew | is-not-empty) {
    brew cleanup --prune=all
    brew autoremove
  }
  if (which bun | is-not-empty) {
    bun pm -g cache rm
  }
  if (which npm | is-not-empty) {
    npm cache clean --force
  }
  if (which uv | is-not-empty) {
    uv cache clean
  }
  if (which go | is-not-empty) {
    go clean -cache
    go clean -modcache
  }
  if (which docker | is-not-empty) {
    docker container prune -f
    docker network prune -f
    docker image prune -a -f
    docker volume prune -f
    docker builder prune -f
    docker buildx prune -f
  }
}
