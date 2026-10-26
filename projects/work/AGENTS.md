# Hadl

## Repositories

- Before editing a repo's files, read its `AGENTS.md` and `REVIEW.md`, even when the session started in another repo.

## Linear

- In the Hadl workspace, do not move issues to Done unless the user explicitly tells you to.
- Embed screenshots and other evidence images in the issue description or a comment: `prepare_file_upload`, PUT the file, then paste the returned markdown. Use `prepare_attachment_upload` only for files people download. Each upload needs its own prepare and PUT within 60 seconds.

## Production

- Applies to manual changes to production systems or data operated by Hadl (such as a deploy, restart, migration, config or secret change, or data write). Only a change that reaches production automatically when an approved PR merges needs no announcement; the PR approval is the ack.
- A production deploy that someone triggers (a `workflow_dispatch` run, a tag pick, a rollout or restart workflow, a `kamal` command) is a manual change, even when it ships an approved PR through CI/CD.
- Before a manual change, draft an announcement for Slack #engineering (`C0AEV5BP35W`) in the user's voice and show it to the user. Post it only after the user confirms.
- After posting, wait until any engineer replies in the thread, then do the action. Do not require a specific person. If nobody replies, ask the user instead of proceeding.
- A database migration is the exception: after posting, apply it without waiting for a reply.
- This does not apply to personal tools or infrastructure just because they work with `hadl-labs` repositories.

## Google Cloud

- The `hadl` configuration uses `tifan@hadl.ai`, selected by `CLOUDSDK_ACTIVE_CONFIG_NAME` in `~/projects/work/mise.toml`. Preserve the global active configuration.
- If gcloud reports `Reauthentication failed`, run `mise run gcloud-auth-check` from `~/projects/work`; its reauth task uses the configured OS keyring. Report unavailable keyring access as a blocker. Never ask for, read, or type the password yourself.
