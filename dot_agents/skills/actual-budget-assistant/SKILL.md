---
name: actual-budget-assistant
description: Query and analyze Actual Budget data using natural language. Use when the user asks about their budget, transactions, account balances, or spending patterns with phrases like "list my transactions", "what's my balance", "show my spending", "transactions in account", "how much did I spend". Works with @actual-app/api Node.js package.
---

# Actual Budget Assistant

Query your Actual Budget data using natural language. This skill helps you analyze transactions, check balances, and review spending across accounts.

## Prerequisites

Install the Actual Budget API package globally:

```bash
npm install -g @actual-app/api
```

Required environment variables:

```bash
export ACTUAL_SERVER_URL=https://actual.example.com
export ACTUAL_PASSWORD=yourpassword
export ACTUAL_SYNC_ID=your-sync-id
```

## Self-Signed Certificates

If your Actual server uses a self-signed or custom CA certificate, set this environment variable:

```bash
export ACTUAL_ALLOW_SELF_SIGNED_CERTS=true
```

This disables TLS certificate verification for the API connection.

## How to Use

When the user asks budget-related questions, use the scripts in `scripts/` directory to fetch data.

### Available Scripts

| Script                 | Purpose                         |
| ---------------------- | ------------------------------- |
| `list-accounts.js`     | List all accounts with balances |
| `list-transactions.js` | Query transactions with filters |
| `get-balance.js`       | Get account balance(s)          |
| `list-categories.js`   | List budget categories          |

### Handling User Queries

**User asks: "List my transactions in account BCA in last january 2026"**

```bash
node scripts/list-transactions.js --account="BCA" --date="last january 2026"
```

**User asks: "What's my BCA balance?"**

```bash
node scripts/get-balance.js --account="BCA"
```

**User asks: "Show my spending last month"** (account not specified)

```bash
node scripts/list-accounts.js
```

Then ask: "Which account? You have: [list from output]"

### When Account is Not Specified

If the user doesn't specify which account, run `list-accounts.js` first, then ask them to clarify:

> "Which account? You have: BCA, Mandiri, Cash, Investment"

### Date Parsing

The scripts accept flexible date formats:

- `last january 2026` → January 2026
- `january 2026` → January 2026
- `last month` → Previous full month
- `this month` → Current month
- `2026-01` → January 2026
- `2026-01-15` → Specific day

### Fuzzy Account Matching

Account names are matched case-insensitively:

- `BCA` matches "BCA", "Rekening BCA", "My BCA Account"
- If no match found, script lists all available accounts

### JSON Output

Add `--json` to any script for structured output:

```bash
node scripts/list-transactions.js --account="BCA" --date="last month" --json
```
