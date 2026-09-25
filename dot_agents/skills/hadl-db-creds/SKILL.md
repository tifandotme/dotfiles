---
name: hadl-db-creds
description: Provides the local command contract for HADL database credentials and tunnels. Use when an agent needs to inspect, traverse, or query HADL, Aquasense, Backoffice, staging, production, or windmill databases.
---

# HADL DB Credentials

For HADL database work, list the entry keys:

```sh
mise run db-creds | jq -r 'keys[]'
```

Pick the entry whose key, `database`, `label`, or `tunnel` matches the request. If more than one entry matches, ask. Treat `db-creds` as a black box. Do not inspect credential storage unless the command is broken.

Run `psql` through `db-psql`. Put the psql arguments after `--`:

```sh
mise run db-psql aquasense_db_staging -- -Atc "select 1"
mise run db-psql aquasense_db_production -- -f query.sql
```

`db-psql` builds the connection with `sslmode=require` and gets the password from TablePlus or from a fresh gcloud access token. It gives the password to `psql` through `PGPASSWORD` and does not print it. Do not get the password yourself for `psql`.

If `db-psql` fails with `Tunnel port N is not listening` and you are inside herdr, run:

```sh
mise run tunnels-start
```

Then wait until the port listens and run the query again. `tunnels-start` finds or creates the exact `tunnels` workspace. It checks ports 5433 (windmill), 5434 (staging), and 5435 (prod), and restarts only the dead tunnel tasks in panes of that workspace. If duplicate `tunnels` workspaces exist, stop and ask the user to close or rename extras.

Outside herdr, ask the user to run:

```sh
mise run tunnels
```

For a client other than `psql`, read the full entry from `mise run db-creds`. Each entry has `host`, `port`, `database`, `user`, `sslmode`, `tunnel`, `tunnel_task`, and `password_source`. For `password_source: "tableplus"`, use `password`. For `password_source: "gcloud-access-token"`, run `mise run gcloud-auth-check`, then use the output of `mise run gcloud-access-token` as the password.

Do not paste passwords, access tokens, or sensitive query results into chat unless the user explicitly asks.

These credentials reach live production data. Read freely; before any statement or admin API call that changes a production row, state the exact change and the rows it touches, then wait for the user to confirm. This holds even when the change looks like a cleanup that follows from a finding you just reported: the user asked for the finding, not for the write.
