command -v exa &> /dev/null || return

opts="-F --no-user --no-permissions --no-filesize --no-time --group-directories-first"
alias ls="exa $opts --sort extension"
alias lsa="exa $opts --sort extension --all"
alias lsn="exa $opts --sort modified"
alias lsna="exa $opts --sort modified --all"
