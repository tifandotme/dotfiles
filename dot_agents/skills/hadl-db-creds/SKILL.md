---
name: hadl-db-creds
description: Provides the shared command contract for connecting to catalogued HADL PostgreSQL databases from macOS or Box with gcloud access tokens.
---

# HADL DB Credentials

The shared connection catalog currently has three entries configured to use gcloud IAM tokens. List their keys with:

```sh
mise run db:list | jq -r '.connections | keys[]'
```

Pick the entry whose key or `database` matches the request. If more than one entry matches, ask. The catalog contains connection metadata only. Do not inspect local credential storage unless a command is broken.

Run `psql` through `db:psql`. Put the psql arguments after `--`:

```sh
mise run db:psql core_db_staging -- -Atc "select 1"
mise run db:psql core_db_production -- -f "$PWD/query.sql"
```

`db:psql` gets a fresh access token for the catalog's explicit gcloud account and passes it to `psql` as `PGPASSWORD`. It does not print the token. Do not get the token yourself for `psql`. The task finds `psql` on `PATH` or under Homebrew's `libpq` prefix.

If the required tunnel is not listening, run the tunnel task in a persistent terminal and leave it running while querying:

```sh
mise run db:tunnel core_db_staging   # one entry
mise run db:tunnel                   # every entry
```

The task starts only tunnels whose local ports are not already listening. It uses `tifan@hadl.ai` explicitly and does not change the machine's active gcloud account.

Entries on the same instance (for example `core_db_staging` and `aquasense_db_staging`) share one local port and tunnel.

Do not paste passwords, access tokens, or sensitive query results into chat unless the user explicitly asks.

These credentials reach live production data. Read freely; before any statement or admin API call that changes a production row, state the exact change and the rows it touches, then wait for the user to confirm. This holds even when the change looks like a cleanup that follows from a finding you just reported: the user asked for the finding, not for the write.
