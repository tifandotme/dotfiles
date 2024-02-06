command -v bun &> /dev/null || return

alias b="bun"

[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
