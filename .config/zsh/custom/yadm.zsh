command -v yadm &> /dev/null || return

alias ya="yadm"
alias yas="yadm status"
alias yal="yadm list -a"
alias yau="yadm add -u && yadm commit -m 'update' && yadm push"
