---
name: actual-budget-assistant
description: Query and analyze Actual Budget data using natural language. Use when the user asks about their budget, transactions, account balances, or spending patterns with phrases like "list my transactions", "what's my balance", "show my spending", "transactions in account", "how much did I spend". Also use for exporting transactions to CSV. Works with @actual-app/api Node.js package.
---

# Actual Budget Assistant

Query your Actual Budget data using natural language. This skill helps you analyze transactions, check balances, review spending across accounts, and export data to CSV.

## Prerequisites

Install the Actual Budget API package globally:

```bash
npm install -g @actual-app/api
```

## Connection Setup

### 1. Local Budget (Required)

Copy your synced budget to:

```bash
mkdir -p ~/.local/share/actual
cp -r ~/path/to/synced/budget/My-Finances-* ~/.local/share/actual/
```

### 2. Server Credentials (Optional)

For live sync with server, set these environment variables:

```bash
export ACTUAL_SERVER_URL=https://actual.example.com
export ACTUAL_PASSWORD=yourpassword
export ACTUAL_SYNC_ID=your-sync-id
```

Without server credentials, the skill works in **offline mode** using only the local budget.

### 3. Self-Signed Certificates (if needed)

```bash
export ACTUAL_ALLOW_SELF_SIGNED_CERTS=true
```

## Connection Behavior

**With server credentials:**
1. Loads local budget from `~/.local/share/actual/My-Finances-*`
2. Connects to server using env vars
3. **Syncs with server** (3 retries with exponential backoff: 1s, 2s, 4s)
4. **If sync fails:** Script exits with error (no stale data fallback)

**Without server credentials (offline mode):**
1. Loads local budget from `~/.local/share/actual/My-Finances-*`
2. Works with local data only (no sync)

This handles Cloud Run cold starts gracefully while ensuring fresh data.

## How to Use

When the user asks budget-related questions:

1. **This skill resolves natural language to structured values:**
   - Account names ("BCA") → account IDs using `utils.js` helpers
   - Date ranges ("last month") → ISO 8601 dates using `utils.js` helpers

2. **Call `actual-cli.js` with structured parameters**

### CLI Commands

| Command | Description | Required Args |
|---------|-------------|---------------|
| `accounts` | List all accounts with balances | None |
| `categories` | List budget categories | None |
| `balance` | Get account balance(s) | None (use `--account-id` for specific) |
| `transactions` | List transactions | `--start`, `--end` |

### Handling User Queries

**User asks: "List my transactions in account BCA in last january 2026"**

The skill resolves:
- "BCA" → account ID via `findAccountByName(api, "BCA")`
- "last january 2026" → dates via `parseDateRange("last january 2026")`

Then calls:
```bash
node scripts/actual-cli.js transactions --account-id="abc-123" --start="2026-01-01" --end="2026-01-31"
```

**User asks: "What's my BCA balance?"**

The skill resolves account name, then:
```bash
node scripts/actual-cli.js balance --account-id="abc-123"
```

**User asks: "Show my spending last month"** (account not specified)

```bash
node scripts/actual-cli.js accounts
```

Then ask: "Which account? You have: [list from output]"

### When Account is Not Specified

If the user doesn't specify which account, run `accounts` command first, then ask them to clarify:

> "Which account? You have: BCA, Mandiri, Cash, Investment"

### Helper Functions (in utils.js)

These functions resolve natural language before calling the CLI:

```javascript
// Parse date ranges to ISO 8601 format
const range = parseDateRange("last month");
// Returns: { start: "2026-01-01", end: "2026-01-31" }

// Resolve account names to IDs
const account = await findAccountByName(api, "BCA");
// Returns: { id: "abc-123", name: "Rekening BCA" }
```

### Date Format

CLI accepts **ISO 8601** dates only: `YYYY-MM-DD`

Examples:
- `--start="2026-01-01" --end="2026-01-31"` (January 2026)
- `--start="2026-02-08" --end="2026-02-08"` (Single day)

### JSON Output

Add `--json` for machine-readable output:

```bash
node scripts/actual-cli.js transactions --account-id="abc-123" --start="2026-01-01" --end="2026-01-31" --json
```

### CSV Export

Add `--csv` to export transactions in CSV format with IDR amounts:

```bash
# Export to file
node scripts/actual-cli.js transactions --account-id="abc-123" --start="2026-01-01" --end="2026-01-31" --csv > bca-jan.csv

# View in terminal
node scripts/actual-cli.js transactions --account-id="abc-123" --start="2026-01-01" --end="2026-01-31" --csv
```

CSV format: `Date,Description,Type,Amount (IDR)`

### Retry Output Example

When server is cold (e.g., Cloud Run):

```
[Sync attempt 1/3 failed, retrying in 1000ms...]
[Sync attempt 2/3 failed, retrying in 2000ms...]
[Synced] Budget updated from server
```

If all retries fail:

```
[Sync attempt 1/3 failed, retrying in 1000ms...]
[Sync attempt 2/3 failed, retrying in 2000ms...]
[Sync attempt 3/3 failed, retrying in 4000ms...]
[Error] Connection timeout
# exits with code 1
```
