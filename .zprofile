# Fedora doesn't have this by default
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Custom config path
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
export ZSH="$XDG_CONFIG_HOME/oh-my-zsh"

# Custom data/bin path
export BUN_INSTALL="$XDG_DATA_HOME/bun"

export PATH="$BUN_INSTALL/bin:$HOME/.cargo/bin:$PATH"
