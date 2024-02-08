header() {
  local message=$1
  echo "\n========================================"
  echo "${message}"
  echo "========================================"
}

up() {
  if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage: up [options]"
    echo "Runs updates for all package managers: dnf, flatpak, bun"
    echo "Options:"
    echo "  -h, --help  Show this help message and exit"
    echo "  -a, --all   Also runs nvm, oh-my-zsh updates"
    echo "  -u, --upgrade [Fedora Release Ver] Run system upgrade"

    return 0
  fi

  if [[ $1 == "-u" || $1 == "--upgrade" ]]; then
    header "Upgrading system..."
    if [[ -z $2 ]]; then
      echo "Please provide Fedora release version (must be greater than current version)"
      return 1
    fi

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

# https://docs.fedoraproject.org/en-US/quick-docs/upgrading-fedora-offline/
clean() {
  if [[ $1 == "-h" || $1 == "--help" ]]; then
    echo "Usage: clean [options]"
    echo "Cleans up system by removing cache and unused packages"
    echo ""
    echo "Options:"
    echo "  -h, --help  Show this help message and exit"
    echo "  --old-kernels  Remove old kernels"
    echo "  --retired-packages  Remove retired packages"
    echo "  --old-symlinks  Remove old symlinks"
    echo "  --systemd-journal  Remove systemd journal logs"
    return 0
  fi

  if [[ -n $1 && $1 != "--remove-old-kernels" && $1 != "--remove-retired-packages" && $1 != "--remove-old-symlinks" ]]; then
    echo "Invalid option: $1"
    return 1
  fi

  if [[ $1 == "--remove-old-kernels" ]]; then
    local old_kernels=($(dnf repoquery --installonly --latest-limit=-2 -q))
    if [ "${#old_kernels[@]}" -eq 0 ]; then
      echo "No old kernels found"
      return 0
    fi

    echo "==> Removing old kernels"
    if ! sudo dnf remove "${old_kernels[@]}"; then
      echo "Failed to remove old kernels"
      return 1
    fi

    echo "Removed old kernels"
    return 0
  fi

  if [[ $1 == "--remove-retired-packages" ]]; then
    if ! command -v remove-retired-packages >/dev/null 2>&1; then
      sudo dnf install remove-retired-packages
    fi

    echo "==> Removing retired packages"
    remove-retired-packages

    return 0
  fi

  if [[ $1 == "--remove-old-symlinks" ]]; then
    if ! command -v symlinks >/dev/null 2>&1; then
      sudo dnf install symlinks
    fi

    echo "==> Removing old symlinks"
    if ! sudo symlinks -r /usr | grep dangling; then
      echo "No old symlinks found"
      return 0
    fi

    echo "Do you want to remove old symlinks? [Y/n]"
    read -r response
    if [[ $response == "Y" || $response == "y" || $response == "" ]]; then
      sudo symlinks -r -d /usr
      echo "Removed old symlinks"
    fi

    return 0
  fi

  if [[ $1 == "--remove-systemd-journal" ]]; then
    echo "==> Removing systemd journal logs"
    sudo journalctl --vacuum-size=100M
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "==> Removing unused system packages"
    sudo dnf autoremove -y
  fi

  if command -v flatpak >/dev/null 2>&1; then
    echo "==> Removing unused flatpak packages"
    flatpak uninstall --unused -y
  fi
}
