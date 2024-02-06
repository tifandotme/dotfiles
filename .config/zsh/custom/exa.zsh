command -v exa &> /dev/null || return

alias ls="exa -lhF --group-directories-first --icons -s extension"
alias lsa="exa -lhFa --group-directories-first --icons -s extension"
