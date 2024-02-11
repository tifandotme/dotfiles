command -v ncu &> /dev/null || return

alias ncu="ncu --cache --cacheFile '$XDG_CACHE_HOME/.ncu-cache.json' --packageManager bun"
alias ncui="ncu --interactive --cache --cacheFile '$XDG_CACHE_HOME/.ncu-cache.json' --packageManager bun"
