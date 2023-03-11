#!/bin/bash
# per-interactive shell startup file

#============= CONFIG
[[ $- != *i* ]] && return # if not running interactively, don't do anything
stty -ixon # disable ctrl-s and ctrl-q.
shopt -s autocd # cd into directory merely by typing the directory name
#HISTSIZE= HISTFILESIZE= # infinite history
#HISTTIMEFORMAT="[%F %T] " # include timestamps on history
#[ -f "$HOME/.config/aliasrc" ] && . "$HOME/.config/aliasrc"'
#export PAGER='/usr/bin/most -s'
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
#if [ $(id -u) -eq 0 ]; then
#	PS1="\[$(tput bold)$(tput setaf 2)\][\[$(tput setaf 1)\]\u\[$(tput setaf 2)\]@\h \[$(tput setaf 1)\]\W\[$(tput setaf 2)\]]\\$ \[$(tput sgr0)\]"
#else
#	PS1="\[$(tput bold)$(tput setaf 2)\][\u@\h \[$(tput setaf 1)\]\W\[$(tput setaf 2)\]]\\$ \[$(tput sgr0)\]"
#fi
# prompt minimal
PS1="\[$(tput setaf 1)\]\W\[$(tput setaf 2)\] $ \[$(tput sgr0)\]"
# use help [program] instead of [program] --help (this will colorize it)
alias bathelp='bat --plain --language=help'
help() {
    "$@" --help 2>&1 | bathelp
}

#============= ALIASES
# ls
# -Gg = long listing like -l, but without group and owner
# -h = human-readable size
# -p = add / to directories
#alias ls='ls -Gghp --time-style=long-iso --color=auto --group-directories-first'
#alias lsa='ls -Gghpa --time-style=long-iso --color=auto --group-directories-first'
alias ls='exa -lh --group-directories-first'
alias lsa='exa -lha --group-directories-first'
alias cat='bat'
alias cl='clear'
alias yd="yt-dlp -S 'ext,res:1080,br,codec' --embed-metadata "
alias rm='rm -rf'
alias npm='npm --no-fund'

export PATH="$PATH:/home/tifan/.bin"
