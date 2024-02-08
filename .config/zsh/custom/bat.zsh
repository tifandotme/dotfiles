command -v bat &> /dev/null || return

alias cat="bat -p"
alias catp="bat" # "cat pretty", shows line numbers

# use help [program] instead of [program] --help (this will colorize it)
help() {
  "$@" --help 2>&1 | bat --plain --language=help
}
