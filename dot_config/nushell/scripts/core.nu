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
alias npx = bunx

alias _ncu = ncu
alias ncu = ncu --format group --root --cache --cacheFile $"($env.XDG_CACHE_HOME)/.ncu-cache.json"

alias cm = chezmoi

alias _pi = ^pi
def --wrapped pi [...args] {
  # pi-code-previews: avoid read/grep tool conflicts with pi-fff.
  # with-env {CODE_PREVIEW_TOOLS: "bash,write,edit,find,ls"} {
  _pi ...$args
  # }
}

alias _claude = ^claude
def --wrapped claude [...args] { _claude --dangerously-skip-permissions --no-chrome ...$args }

alias _codex = ^codex
def --wrapped codex [...args] { _codex --dangerously-bypass-approvals-and-sandbox ...$args }

alias _cursor-gui = ^cursor
def --wrapped cursor-gui [...args] {
  let cursor_config_dir = $env.HOME | path join ".cursor"
  with-env {CURSOR_CONFIG_DIR: $cursor_config_dir} {
    _cursor-gui --chat ...$args
  }
}

alias _cursor-agent = ^cursor-agent
def --wrapped cursor [...args] {
  let cursor_config_dir = $env.HOME | path join ".cursor"
  with-env {CURSOR_CONFIG_DIR: $cursor_config_dir} {
    _cursor-agent --yolo ...$args
  }
}

alias _btm = btm

alias tf = trafilatura

alias _amp = amp

alias _rg = rg
alias rg = rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview

alias gdu = gdu-go
