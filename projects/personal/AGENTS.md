## Linear

- For work likely to span sessions or require coordination, ask whether to track it unless a relevant Linear issue already exists, and include the issue identifier in branch, commit, and PR names when relevant.
- Use the Citra Linear workspace for repositories owned by `tifandotme`. If the remote is missing or has another owner, ask before Linear access.

## Google Cloud

- Before running `gcloud`, check that `CLOUDSDK_ACTIVE_CONFIG_NAME` is `personal`. If it is unset or different, prefix the command with `CLOUDSDK_ACTIVE_CONFIG_NAME=personal`.
- Before a consequential operation, verify the selected account and project. Do not change the shared default with `gcloud config configurations activate`.
- If credentials are missing, run `mise -C ~/projects/personal run gcloud-login`.
