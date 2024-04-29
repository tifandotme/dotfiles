command -v ncu &> /dev/null || return

alias ncu="ncu --format group --root --cache --cacheFile '$XDG_CACHE_HOME/.ncu-cache.json' --packageManager bun"
alias ncui="ncu --format group --root --interactive --cache --cacheFile '$XDG_CACHE_HOME/.ncu-cache.json' --packageManager bun"
