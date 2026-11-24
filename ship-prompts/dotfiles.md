Ship this thread's changes to origin/master in tifandotme/dotfiles.

1. Commit only changes made in this thread. Leave other staged, unstaged, and untracked changes alone. Ask only if they block a safe commit, rebase, or push.
2. Fetch origin and rebase onto origin/master.
3. Run `mise run dotfiles:check`. It must pass.
4. Push to origin/master. If rejected, fetch, rebase, and retry. Ask me before resolving a substantive conflict. Rerun the check only if the rebase changed files.
5. Run `chezmoi apply` on this machine.
6. Then sync the other machine (`macbook` from `box`, `box-tailnet` from the MacBook):
   `ssh -o BatchMode=yes <host> 'git -C ~/.local/share/chezmoi pull --rebase --autostash && chezmoi apply'`
   Never force, reset, or discard anything there. If it is unreachable or conflicts, report it and stop.
7. Create no threads or runners. Report each machine's HEAD.
