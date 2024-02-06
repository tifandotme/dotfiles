function header() {
  local message=$1
  echo "\n========================================"
  echo "${message}"
  echo "========================================"
}

function up() {
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

  if command -v nvm >/dev/null 2>&1; then
    header "Updating nvm..."
    PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
  fi
}
