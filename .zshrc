# docs: https://github.com/ohmyzsh/ohmyzsh/wiki/Settings/

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# hyphen-insensitive completion.
HYPHEN_INSENSITIVE="true"

# disable setting terminal title when running a command or printing the prompt
DISABLE_AUTO_TITLE="true"

# command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

ZSH_CUSTOM="$XDG_CONFIG_HOME/zsh/custom"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
	git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
	git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/*
plugins=(
	zsh-autosuggestions     # add autosuggestions
	zsh-syntax-highlighting # add fish-like syntax highlithing to commands

	vi-mode    # extend zsh vi mode
	aliases    # add alias aliases
	history    # add history aliases
	dirhistory # Alt+Arrow to navigate directory history

	bun # cache completions for bun
	nvm # source and add autocompletions for nvm

	starship # init starship prompt
)

source "$ZSH/oh-my-zsh.sh"

# C-space to accept autosuggestion
bindkey '^ ' autosuggest-accept

if [[ -n $SSH_CONNECTION ]]; then
	export EDITOR='vi'
else
	export EDITOR='hx'
fi

# bun completions
[ -s "/home/tifan/.local/share/bun/_bun" ] && source "/home/tifan/.local/share/bun/_bun"
