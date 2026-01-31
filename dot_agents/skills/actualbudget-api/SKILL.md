---
name: actualbudget-api
description: Integrate with Actual Budget via its JavaScript/Node.js API for personal finance automation. Use for managing budgets, transactions, accounts, categories, payees, rules, and schedules programmatically.
---

# Actual Budget API

Integration with [Actual Budget](https://actualbudget.org/) - an open-source personal finance app.

## Prerequisites

Install the Actual API package:

```bash
npm install @actual-app/api
```

## Quick Start

```javascript
const api = require("@actual-app/api");

async function main() {
  await api.init({
    dataDir: "/path/to/actual-data",
    serverURL: "https://actual.example.com", // Optional: for sync server
    password: "your-password", // Optional: for sync server
  });

  await api.downloadBudget("budget-sync-id");

  // Work with the budget...
  const accounts = await api.getAccounts();
  console.log(accounts);

  await api.shutdown();
}

main();
```

## API Overview

### Initialization

- `init(config)` - Initialize the API connection
- `shutdown()` - Close the connection cleanly
- `downloadBudget(syncId)` - Download budget from sync server
- `loadBudget(path)` - Load budget from local file

### Budgets

- `getBudgetMonths()` - Get all budget months
- `getBudgetMonth(month)` - Get budget for specific month (YYYY-MM)
- `setBudgetAmount(month, categoryId, amount)` - Set budgeted amount
- `setBudgetCarryover(month, categoryId, flag)` - Enable/disable carryover
- `holdBudgetForNextMonth(month, amount)` - Hold funds for next month
- `resetBudgetHold(month)` - Reset held funds

### Transactions

- `importTransactions(accountId, transactions[])` - Import with deduplication
- `addTransactions(accountId, transactions[], runTransfers?, learnCategories?)` - Add raw transactions
- `getTransactions(accountId, startDate, endDate)` - Get transactions in date range
- `updateTransaction(id, fields)` - Update transaction fields
- `deleteTransaction(id)` - Delete a transaction

### Accounts

- `getAccounts()` - Get all accounts
- `createAccount(account, initialBalance?)` - Create new account
- `updateAccount(id, fields)` - Update account fields
- `closeAccount(id, transferAccountId?, transferCategoryId?)` - Close account
- `reopenAccount(id)` - Reopen closed account
- `deleteAccount(id)` - Delete account permanently
- `getAccountBalance(id, cutoff?)` - Get account balance

### Categories

- `getCategories()` - Get all categories
- `createCategory(category)` - Create category
- `updateCategory(id, fields)` - Update category
- `deleteCategory(id)` - Delete category

### Category Groups

- `getCategoryGroups()` - Get all category groups
- `createCategoryGroup(group)` - Create group
- `updateCategoryGroup(id, fields)` - Update group
- `deleteCategoryGroup(id)` - Delete group

### Payees

- `getPayees()` - Get all payees
- `createPayee(payee)` - Create payee
- `updatePayee(id, fields)` - Update payee
- `deletePayee(id)` - Delete payee
- `mergePayees(targetId, sourceIds[])` - Merge multiple payees

### Rules

- `getRules()` - Get all rules
- `getPayeeRules(payeeId)` - Get rules for payee
- `createRule(rule)` - Create rule
- `updateRule(id, fields)` - Update rule
- `deleteRule(id)` - Delete rule

### Schedules

- `getSchedules()` - Get all schedules
- `createSchedule(schedule)` - Create schedule
- `updateSchedule(id, fields)` - Update schedule
- `deleteSchedule(id)` - Delete schedule

## Data Types

### Primitives

| Type     | Format                                   |
| -------- | ---------------------------------------- |
| `id`     | UUID string                              |
| `month`  | `YYYY-MM`                                |
| `date`   | `YYYY-MM-DD`                             |
| `amount` | Integer (no decimals). $120.30 = `12030` |

### Transaction Object

```javascript
{
  id: 'uuid',              // Optional for create
  account: 'account-id',   // Required
  date: '2024-01-15',      // Required
  amount: 12030,           // Integer cents
  payee: 'payee-id',       // Optional (create only, overrides payee_name)
  payee_name: 'Kroger',    // Optional (create only)
  imported_payee: 'KROGER #1234', // Optional
  category: 'category-id', // Optional
  notes: 'Groceries',      // Optional
  imported_id: 'bank-123', // Optional (for dedup)
  transfer_id: 'uuid',     // Optional (internal use)
  cleared: true,           // Optional
  subtransactions: []      // Optional (for splits, create/get only)
}
```

### Account Object

```javascript
{
  id: 'uuid',
  name: 'Checking Account',
  type: 'checking',        // checking, savings, credit, investment, mortgage, debt, other
  offbudget: false,
  closed: false
}
```

### Category Object

```javascript
{
  id: 'uuid',
  name: 'Food',
  group_id: 'group-uuid',  // Required
  is_income: false
}
```

### Category Group Object

```javascript
{
  id: 'uuid',
  name: 'Bills',
  is_income: false,
  categories: []           // Populated in get only
}
```

### Payee Object

```javascript
{
  id: 'uuid',
  name: 'Kroger',
  transfer_acct: 'account-id',  // If this payee is a transfer target
  favorite: false
}
```

## Common Patterns

### Import Bank Transactions

```javascript
const transactions = [
  {
    date: "2024-01-15",
    amount: -4500, // Negative = expense
    payee_name: "Netflix",
    imported_id: "netflix-jan-2024-001",
  },
];

const result = await api.importTransactions(accountId, transactions);
console.log("Added:", result.added);
console.log("Updated:", result.updated);
console.log("Errors:", result.errors);
```

### Batch Operations

```javascript
await api.batchBudgetUpdates(async () => {
  await api.setBudgetAmount("2024-01", foodCategoryId, 50000);
  await api.setBudgetAmount("2024-01", gasCategoryId, 20000);
  await api.setBudgetAmount("2024-01", funCategoryId, 10000);
});
```

### Split Transactions

```javascript
await api.addTransactions(
  accountId,
  [
    {
      date: "2024-01-15",
      amount: -12000,
      payee_name: "Costco",
      subtransactions: [
        { amount: -8000, category: foodCategoryId, notes: "Groceries" },
        { amount: -4000, category: householdCategoryId, notes: "Supplies" },
      ],
    },
  ],
  false,
  false,
);
```

### Create Transfer

```javascript
// Find transfer payee for destination account
const payees = await api.getPayees();
const transferPayee = payees.find((p) => p.transfer_acct === targetAccountId);

await api.addTransactions(sourceAccountId, [
  {
    date: "2024-01-15",
    amount: -100000,
    payee: transferPayee.id, // This creates the transfer
  },
]);
```

### Close Account with Balance Transfer

```javascript
// Close account, transferring balance to another account
await api.closeAccount(
  oldAccountId,
  targetAccountId, // Transfer balance here
  categoryId, // Optional: category for the transfer (if off-budget)
);
```

## Error Handling

Always wrap API calls in try-catch and ensure `shutdown()` is called:

```javascript
async function main() {
  try {
    await api.init({ dataDir: "/path/to/data" });
    // ... do work
  } catch (err) {
    console.error("Budget error:", err.message);
  } finally {
    await api.shutdown();
  }
}
```

## Querying Data (ActualQL)

Run custom queries for advanced filtering:

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

## Bank Sync

Trigger automatic bank synchronization:

```javascript
await api.runBankSync(accountId);
```

## Full API Reference

For complete method signatures and all fields, see [references/api-reference.md](references/api-reference.md).
