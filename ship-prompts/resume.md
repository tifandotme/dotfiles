Ship this thread's changes to `tifandotme/resume`. Commit only this thread's changes.

- **General resume:** Rebase onto `origin/master`. For Typst changes, verify the public PDF with `mise run build-public`. Push directly to `origin/master` without force and report the result of the automatic `Deploy Resume PDF` run and the public URL (`https://tifan.me/resume`). Leave manual redeploys to me.
- **Targeted application:** Keep the changes on `apply/<company>-<role>`. Run `mise run build`, push that branch without force, and report the local PDF path for me to submit. Never merge company-specific wording into `master` or deploy it.

If you cannot tell whether the changes are for the public resume or a specific application, ask before pushing.
