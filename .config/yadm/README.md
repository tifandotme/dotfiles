# yadm Bootstrap Setup

## Prerequisites

- Git
- SSH public and private keys encrypted by yadm

## Usage

1. `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
1. `apt install yadm -y` (macOS) or equivalent
1. `yadm clone https://github.com/tifandotme/dotfiles.git` (DO NOT bootstrap yet)
1. `yadm decrypt` (see Bitwarden notes for password)
1. `yadm bootstrap`

## One-liner

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
  sudo apt install yadm -y && \
  yadm clone https://github.com/tifandotme/dotfiles.git && \
  yadm decrypt && \
  yadm bootstrap
```
