command -v bat &> /dev/null || return

alias cat="bat -p"

# use help [program] instead of [program] --help (this will colorize it)
help() {
  "$@" --help 2>&1 | bat --plain --language=help
}

# colorize man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
