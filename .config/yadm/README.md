# Bootstrap Guide

## Prerequisites

- Git
- SSH public and private keys encrypted by yadm (homebrew won't work without ssh configured)
- yadm encryption pass ready (see in Bitwarden note)

## Usage (bash)

```bash
echo "DO NOT press y when asked to bootstrap during clone!" && \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
  sudo apt install yadm -y && \
  yadm clone https://github.com/tifandotme/dotfiles.git && \
  yadm decrypt && \
  yadm bootstrap
```
