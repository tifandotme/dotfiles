Ship this thread's changes to `tifandotme/box`.

1. Commit only this thread's changes. Fetch `origin`, rebase onto `origin/master`, and run the checks `AGENTS.md` calls for on the touched areas.
2. Push directly to `origin/master` without force. Use a PR only if I asked for one.
3. Report the shipped commit and the results of any automatic checks and Windmill staging sync it triggers.
4. Dispatch a manual workflow, including `Windmill production`, only when I explicitly ask for it. Asking to Ship or push is not authorization. For `Windmill production`, run `plan` and review the output before `apply`; a request for `plan` alone does not authorize `apply`. Leave infrastructure applies and direct writes to the Box host to me.
