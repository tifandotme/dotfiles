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

alias oc = opencode

alias _claude = ^claude
def claude [...args] { IS_DEMO=1 _claude --dangerously-skip-permissions ...$args }

alias _btm = btm

alias tf = trafilatura

alias _amp = amp

alias _rg = rg
alias rg = rg --smart-case --glob '!{.git/*,out/*,**/node_modules/**}' --max-columns-preview

alias gdu = gdu-go

# Run a command and notify when complete via cmux
# Usage: notify-after {|| updater start }
export def notify-after [cmd: closure --label: string = "Command"] {
  let start_time = (date now)

  # Run the closure with error handling - returns a record with success flag
  let outcome = try {
    {result: (do $cmd) success: true}
  } catch {|e|
    print -e $"Error: ($e)"
    {result: null success: false}
  }

  let duration = ((date now) - $start_time | format duration sec | str replace " sec" "s")

  # Build notification
  let title = if $outcome.success { $"✓ ($label) Complete" } else { $"✗ ($label) Failed" }
  let body = if $outcome.success {
    $"Completed in ($duration)"
  } else {
    $"Failed after ($duration)"
  }

  # Send notification via cmux CLI
  ^cmux notify --title $title --body $body

  # Return result or error
  if $outcome.success {
    return $outcome.result
  } else {
    error make {msg: $"($label) failed"}
  }
}
