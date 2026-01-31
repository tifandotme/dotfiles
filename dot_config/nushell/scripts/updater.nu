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
  }

  if (which bun | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)bun(ansi reset) global packages"
    bun update --global --latest
  }

  if (which pnpm | is-not-empty) {
    print $"\n(ansi green_bold)==>(ansi reset) Upgrading (ansi green)pnpm(ansi reset) global packages"
    pnpm update --global --latest
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
