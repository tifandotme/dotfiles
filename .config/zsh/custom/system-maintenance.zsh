header() {
  local message=$1
  echo "\n========================================"
  echo "${message}"
  echo "========================================"
}

up() {
  # show help when -h or --help is passed
  if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage: up [options]"
    echo "Runs updates for all package managers: dnf, flatpak, bun"
    echo "Options:"
    echo "  -h, --help  Show this help message and exit"
    echo "  -a, --all   Also runs nvm, oh-my-zsh updates"
    # run -u [fedora version] to run system upgrade
    echo "  -u, --upgrade [Fedora Release Ver] Run system upgrade"

    return 0
  fi

  if [[ $1 == "-u" || $1 == "--upgrade" ]]; then
    header "Upgrading system..."
    sudo dnf upgrade --refresh -y
    sudo dnf system-upgrade download --releasever=$2 -y
    sudo dnf system-upgrade reboot

    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    header "Updating dnf packages..."
    sudo dnf up -y
  fi

  if command -v flatpak >/dev/null 2>&1; then
    header "Updating flatpak packages..."
    flatpak update --noninteractive
  fi

  if command -v bun >/dev/null 2>&1; then
    header "Updating bun packages..."
    bun upgrade

    header "Updating global bun packages..."
    bun update --global
  fi

  if [[ $1 == "-a" || $1 == "--all" ]]; then
    if command -v nvm >/dev/null 2>&1; then
      header "Updating nvm..."
      PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
    fi

    if command -v omz >/dev/null 2>&1; then
      header "Updating oh-my-zsh..."
      omz update
    fi
  fi
}
