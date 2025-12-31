# Bootstrap Guide

## Prerequisites

- Git
- SSH public and private keys encrypted by yadm (homebrew won't work without ssh configured)
- yadm encryption pass ready (see in Bitwarden note)

## Usage (bash)

```bash
bash -c '
set -e

echo "--- Installing homebrew ---"
echo ""
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo ""
echo "--- Installing yadm ---"
echo ""
sudo apt install yadm -y

echo ""
echo "--- Cloning dotfiles ---"
echo ""
yadm clone https://github.com/tifandotme/dotfiles.git

echo ""
echo "--- Decrypting files ---"
echo ""
yadm decrypt

echo ""
echo "--- Running bootstrap ---"
echo ""
yadm bootstrap

echo ""
echo "Done!"
'
```
