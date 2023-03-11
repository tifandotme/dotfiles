#!/bin/bash
# per-interactive shell startup file

# if not running interactively, don't do anything
[[ $- != *i* ]] && return
# cd into directory merely by typing the directory name
shopt -s autocd
# include timestamps in history
HISTTIMEFORMAT="[%F %T] "

# load aliasrc
[ -f "$HOME/.config/aliasrc" ] && . "$HOME/.config/aliasrc"

export OPENAI_API_KEY='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'
# colored man page
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# prompt
PS1="\[$(tput setaf 1)\]\W\[$(tput setaf 2)\] $ \[$(tput sgr0)\]"
# use help [program] instead of [program] --help (this will colorize it)

export PATH="$PATH:/home/tifan/.bin"
