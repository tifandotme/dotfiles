command -v bat &> /dev/null || return

alias cat="bat"

# use help [program] instead of [program] --help (this will colorize it)
help() {
  "$@" --help 2>&1 | bat --plain --language=help
}
