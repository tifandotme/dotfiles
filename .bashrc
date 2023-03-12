#!/bin/bash
# per-interactive shell startup file

# if not running interactively, don't do anything
[[ $- != *i* ]] && return
# cd into directory merely by typing the directory name
shopt -s autocd
# include timestamps in history
HISTTIMEFORMAT="[%F %T] "

# prompt
PS1="\[$(tput setaf 1)\]\W\[$(tput setaf 2)\] $ \[$(tput sgr0)\]"

# additional path
# export PATH="$PATH:/home/tifan/.local/bin"

# load aliasrc
[ -f "$HOME/.config/aliasrc" ] && . "$HOME/.config/aliasrc"

# load environment variables
[ -f "$HOME/.config/envrc" ] && . "$HOME/.config/envrc"
[ -f "$HOME/.config/envrc.secret" ] && . "$HOME/.config/envrc.secret"

# pnpm
export PNPM_HOME="/home/tifan/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end test
