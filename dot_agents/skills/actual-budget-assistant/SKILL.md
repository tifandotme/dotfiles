---
name: actual-budget-assistant
description: "Query and analyze Actual Budget data using natural language. Use when the user asks about their budget, transactions, account balances, or spending patterns with phrases like 'list my transactions', 'what is my balance', 'show my spending', 'transactions in account', 'how much did I spend'. Also use for exporting transactions to CSV. Works with @actual-app/api Node.js package."
---

# Actual Budget Assistant

Query your Actual Budget data using natural language. Fast, offline-capable, and clean output.

## Prerequisites

1. **Install the Actual Budget API package:**

   ```bash
   npm install -g @actual-app/api
   ```

2. **Set your server credentials:**

   ```bash
   export ACTUAL_SERVER_URL=https://actual.example.com
   export ACTUAL_PASSWORD=yourpassword
   export ACTUAL_SYNC_ID=your-sync-id
   ```

3. **Self-signed certificates (if needed):**

   ```bash
   export ACTUAL_ALLOW_SELF_SIGNED_CERTS=true
   ```

4. **Run initial setup to download your budget:**
   ```bash
   node scripts/setup-budget.js
   ```

## Quick Start

```bash
# All accounts balance
node scripts/actual-cli.js balance --offline

# Specific account (uses partial name matching)
node scripts/actual-cli.js balance --account=jago --offline

# Transactions for a date range
node scripts/actual-cli.js transactions --start=2026-01-01 --end=2026-01-31 --account=bca --offline

# Full power (sync with server)
node scripts/actual-cli.js balance
```

## Features

### 1. Offline Mode (`--offline`)

Works entirely from local cache. No server connection needed. Fast and reliable.

### 2. Account Name Resolution

Use partial names instead of UUIDs:

- `--account=jago` matches "Jago (Utama+GoPay)"
- `--account=bca` matches "BCA"

### 3. Clean Output

Filters API noise (TLS warnings, breadcrumbs, sync logs) automatically. Only shows the data you want.

### 4. Graceful Sync Failures

If server sync fails, automatically falls back to cached data.

## CLI Reference

```
Usage: actual-cli.js <command> [options]

Commands:
  transactions --start=DATE --end=DATE [--account=NAME] [--limit=N]
  balance [--account=NAME]

Options:
  --offline    Work from cache only (no server sync)

Examples:
  actual-cli.js transactions --start=2026-01-01 --end=2026-01-31
  actual-cli.js transactions --start=2026-01-01 --end=2026-01-31 --account=jago
  actual-cli.js balance --account=bca
  actual-cli.js balance --offline
```

## Natural Language Queries

| User asks                              | What happens                                   |
| -------------------------------------- | ---------------------------------------------- |
| "What's my BCA balance?"               | Resolves "BCA" → account ID → runs `balance`   |
| "List transactions in Jago last month" | Resolves dates + account → runs `transactions` |
| "Export my spending to CSV"            | Runs `transactions` with CSV output            |

## Pro Tips

- **Always use `--offline`** for instant reads (data is cached locally)
- **Date formats**: `2026-01-01`, `2026-01` (full month)
- **First run** must download budget from server (or use `setup-budget.js`)
