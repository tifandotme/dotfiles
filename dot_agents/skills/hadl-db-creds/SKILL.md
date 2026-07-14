---
name: hadl-db-creds
description: Provides the local command contract for HADL database credentials and tunnels. Use when an agent needs to inspect, traverse, or query HADL, Aquasense, Backoffice, staging, production, or windmill databases.
---

# HADL DB Credentials

For HADL database work, get connection metadata as JSON:

```sh
mise run db-creds
```

Treat the command as a black box. Do not inspect credential storage unless the command is broken.

Pick the entry whose key, `database`, `label`, or `tunnel` matches the request. If more than one entry matches, ask. Each entry has `host`, `port`, `database`, `user`, `sslmode`, `tunnel`, and `tunnel_task`.

For `password_source: "tableplus"`, use `password`. For `password_source: "gcloud-access-token"`, run:

```sh
mise run gcloud-auth-check
mise run gcloud-access-token
```

and use the fresh token as the PostgreSQL password.

Before querying, check whether the needed local `port` is listening.

If not listening and inside herdr, run:

```sh
mise run tunnels-start
```

It finds or creates the exact `tunnels` workspace and runs `mise run tunnels` in its single tab. If duplicate `tunnels` workspaces exist, stop and ask the user to close or rename extras.

Outside herdr, ask the user to run:

```sh
mise run tunnels
```

Use `sslmode=require` for `psql` connections through these tunnels. Do not paste passwords, access tokens, or sensitive query results into chat unless the user explicitly asks.
