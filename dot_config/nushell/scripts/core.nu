alias rm = rm -rf
alias grep = grep --color=auto

alias _ls = ls
alias ls = eza --group-directories-first --classify=auto --sort=extension --oneline
alias lsa = eza --group-directories-first --classify=auto --sort=extension --oneline --all

alias _cat = cat
alias cat = bat --plain --theme=base16

alias lzg = lazygit

alias lzd = lazydocker

alias d = docker

alias t = terraform

alias g = git

alias b = bun

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json"

alias cm = chezmoi

alias oc = opencode

alias _btm = btm

alias tf = trafilatura

alias _amp = amp

alias _rg = rg
alias rg = rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview

alias gdu = gdu-go
