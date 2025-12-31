# Bootstrap Guide

## Prerequisites

- Git
- SSH public and private keys encrypted by yadm (homebrew won't work without ssh configured)

## Usage (bash)

```bash
echo "DO NOT press y when asked to bootstrap during clone!" && \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
  sudo apt install --fix-broken && \ # fix "E: Sub-process /usr/bin/dpkg returned an error code (1)" during bootstrap
  sudo apt install yadm -y && \
  yadm clone https://github.com/tifandotme/dotfiles.git && \
  yadm decrypt && \
  yadm bootstrap
```
