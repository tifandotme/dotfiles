---
name: actual-budget-api-expert
description: Integrate with Actual Budget via its JavaScript/Node.js API for personal finance automation. Use when managing budgets, transactions, accounts, categories, payees, rules, and schedules programmatically, or when working with the @actual-app/api package.
---

# Actual Budget API

Integration with [Actual Budget](https://actualbudget.org/) - an open-source, local-first personal finance app.

## Prerequisites

```bash
npm install @actual-app/api
```

## Quick Start

```javascript
const api = require("@actual-app/api");

async function main() {
  try {
    await api.init({
      dataDir: "/path/to/actual-data",
      serverURL: "https://actual.example.com", // Optional
      password: "your-password", // Optional
    });

    await api.downloadBudget("budget-sync-id");

    const accounts = await api.getAccounts();
    console.log(accounts);
  } finally {
    await api.shutdown();
  }
}

main();
```

## Critical: Amount Handling

Actual stores amounts as integers (no decimals). **Always convert currency amounts:**

```javascript
// $120.30 → 12030
const amountInt = api.utils.amountToInteger(120.3);

// 12030 → 120.30
const amountFloat = api.utils.integerToAmount(12030);
```

## Key Methods

### Connection

- `init(config)` - Initialize API
- `shutdown()` - Close connection cleanly
- `downloadBudget(syncId, password?)` - Download from sync server
- `sync()` - Manual sync with server
- `runBankSync(accountId?)` - Sync transactions from linked bank accounts

### Transactions

- `importTransactions(accountId, transactions[])` - Import with deduplication/rules
- `addTransactions(accountId, transactions[], runTransfers?, learnCategories?)` - Add raw (no dedup)
- `getTransactions(accountId, startDate, endDate)` - Get transactions in date range
- `updateTransaction(id, fields)` / `deleteTransaction(id)`

**Important:** Use `importTransactions` for bank imports (handles dedup). Use `addTransactions` for bulk data migration.

### Accounts

- `getAccounts()` / `createAccount(account, initialBalance?)`
- `updateAccount(id, fields)` / `closeAccount(id, transferAcct?, transferCat?)` / `reopenAccount(id)`

### Categories & Groups

- `getCategories()` / `createCategory({name, group_id})` / `updateCategory(id, fields)`
- `getCategoryGroups()` / `createCategoryGroup({name})`

### Payees

- `getPayees()` / `createPayee({name})` / `mergePayees(targetId, sourceIds[])`

### Rules & Schedules

- `getRules()` / `createRule({conditions, actions})`
- `getSchedules()` / `createSchedule({name, payee, account, amount})`

### Budget

- `getBudgetMonth(month)` - Get budget for month (YYYY-MM)
- `setBudgetAmount(month, categoryId, amount)` - Set budgeted amount
- `batchBudgetUpdates(callback)` - Batch multiple updates for performance

## Common Patterns

### Import from Bank (with dedup)

```javascript
const transactions = [
  {
    date: "2024-01-15",
    amount: api.utils.amountToInteger(-45.0), // Expense
    payee_name: "Netflix",
    imported_id: "netflix-jan-001", // For deduplication
  },
];

const result = await api.importTransactions(accountId, transactions);
console.log("Added:", result.added, "Updated:", result.updated);
```

### Bulk Data Migration (no dedup)

Use `runImport` mode when migrating from other apps. Creates new budget file, runs faster.

```javascript
await api.runImport("New-Budget-Name", async () => {
  for (const acct of data.accounts) {
    const id = await api.createAccount(convertAccount(acct));
    await api.addTransactions(id, convertTransactions(acct.transactions));
  }
});
```

### Batch Budget Updates

```javascript
await api.batchBudgetUpdates(async () => {
  await api.setBudgetAmount(
    "2024-01",
    foodCategoryId,
    api.utils.amountToInteger(500),
  );
  await api.setBudgetAmount(
    "2024-01",
    gasCategoryId,
    api.utils.amountToInteger(200),
  );
});
```

### Split Transactions

```javascript
await api.addTransactions(accountId, [
  {
    date: "2024-01-15",
    amount: api.utils.amountToInteger(-120),
    payee_name: "Costco",
    subtransactions: [
      {
        amount: api.utils.amountToInteger(-80),
        category: foodId,
        notes: "Groceries",
      },
      {
        amount: api.utils.amountToInteger(-40),
        category: householdId,
        notes: "Supplies",
      },
    ],
  },
]);
```

### Create Transfer Between Accounts

```javascript
const payees = await api.getPayees();
const transferPayee = payees.find((p) => p.transfer_acct === targetAccountId);

await api.addTransactions(sourceAccountId, [
  {
    date: "2024-01-15",
    amount: api.utils.amountToInteger(-1000),
    payee: transferPayee.id, // Creates transfer
  },
]);
```

## HTTPS with Self-Signed Certificates

If using self-signed certs, set one of these before running:

```bash
# Option 1: Trust specific certificate
export NODE_EXTRA_CA_CERTS=/path/to/cert.pem

# Option 2: Disable TLS verification (not recommended for production)
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## Querying with ActualQL

```javascript
const result = await api.runQuery({
  table: "transactions",
  select: ["date", "amount", "payee.name"],
  where: {
    date: { gte: "2024-01-01" },
    amount: { lt: 0 },
  },
});
```

## Reference

- **Complete API reference:** [references/api-reference.md](references/api-reference.md)
- **Extended examples:** [references/examples.md](references/examples.md)
