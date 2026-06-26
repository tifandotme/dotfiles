---
name: hadl-db-creds
description: Provides the local command contract for HADL database credentials and tunnels. Use when an agent needs to inspect, traverse, or query HADL, Aquasense, Backoffice, staging, production, or windmill databases.
disable-model-invocation: true
---

# HADL DB Credentials

For HADL database work, get credentials with:

```sh
mise run db-creds
```

It prints grouped `dotenv` credentials, including passwords. Treat the command as a black box. Do not inspect credential storage unless the command is broken.

Start the matching tunnel before connecting:

- `mise run tunnel-windmill`
- `mise run tunnel-staging`
- `mise run tunnel-prod`
- `mise run tunnels`

Before querying, check whether the needed local port is listening. If not, and `HERDR_ENV=1`, load the `herdr` skill, create a new workspace/space with a new tab, and run the matching tunnel there. If not running inside herdr, ask the user to start the tunnel.

Output shape:

```dotenv
# staging
DB_HOST=localhost
DB_PORT=5434
DB_NAME=...
DB_USER=...
DB_PASSWORD=...

# prod
DB_HOST=localhost
DB_PORT=5435
DB_NAME=...
DB_USER=...
DB_PASSWORD=...
```

Do not paste passwords or sensitive query results into chat unless the user explicitly asks.
