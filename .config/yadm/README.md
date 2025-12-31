# Bootstrap Guide

Machines atm:

- ##distro.Ubuntu,hostname.box
- ##os.Darwin

## Prerequisites

- Git
- SSH public and private keys encrypted by yadm (homebrew won't work without ssh configured)
- yadm encryption pass ready (see in Bitwarden note)

## Usage (bash)

```bash
bash -c '
set -e

echo -e "\033[1;36m--- Installing homebrew ---\033[0m"
echo ""
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo ""
echo -e "\033[1;36m--- Installing yadm ---\033[0m"
echo ""
sudo apt install yadm -y

echo ""
echo -e "\033[1;36m--- Cloning dotfiles & bootstrap ---\033[0m"
echo ""
yadm clone --bootstrap https://github.com/tifandotme/dotfiles.git

echo ""
echo "Done!"
'
```
