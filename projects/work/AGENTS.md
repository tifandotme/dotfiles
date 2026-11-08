# Hadl.ai

Hadl.ai builds AI products and expert-labelled data for aquaculture and other physical-world industries.

## Repositories

- Before editing a repo's files, read its `AGENTS.md`, and its `REVIEW.md` when it has one, even when the session started in another repo.

## Linear

- For work likely to span sessions or require coordination, ask whether to track it unless a relevant Linear issue already exists, and include the issue identifier in branch, commit, and PR names when relevant.
- Use the Hadl Linear workspace for repositories owned by `hadl-labs`. If the remote is missing or has another owner, ask before Linear access.
- In the Hadl workspace, do not move issues to Done unless the user explicitly tells you to.
- Embed screenshots and other evidence images in the issue description or a comment: `prepare_file_upload`, PUT the file, then paste the returned markdown. Use `prepare_attachment_upload` only for files people download. Each upload needs its own prepare and PUT within 60 seconds.

## Production

- Manual changes to production systems or data (a deploy, restart, migration, config or secret change, or data write) need an announcement for Slack #engineering (`C0AEV5BP35W`). Draft it in the user's voice, show it, and post only after the user confirms. Then do the action without waiting for a reply.
- A deploy someone triggers (a `workflow_dispatch` run, a tag pick, a rollout or restart workflow, a `kamal` command) is manual, even when it ships an approved PR through CI/CD. A change that reaches production automatically when an approved PR merges needs no announcement; the PR approval is the ack.
- Personal tools and infrastructure are out of scope, even when they work with `hadl-labs` repositories.

## Google Cloud

- Before running `gcloud`, check that `CLOUDSDK_ACTIVE_CONFIG_NAME` is `hadl`. If it is unset or different, prefix the command with `CLOUDSDK_ACTIVE_CONFIG_NAME=hadl`.
- Before a consequential operation, verify the selected account and project. Do not change the shared default with `gcloud config configurations activate`.
- If credentials are missing, run `mise -C ~/projects/work run gcloud-login`.
- If gcloud reports `Reauthentication failed`, run `mise -C ~/projects/work run gcloud-auth-check`, which reauthenticates on its own. Never read `~/.secrets` or type the password yourself.

## Amp links

- Hadl PRs, Linear issues, Slack messages and commits carry no Amp attachments, thread URLs, `Amp-Thread-ID` trailers or other `ampcode.com` links; the team cannot open them. Upload images through GitHub or Linear and link repo, PR or Linear URLs.
