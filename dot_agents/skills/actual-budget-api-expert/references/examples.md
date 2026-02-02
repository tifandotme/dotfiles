# Actual Budget API Examples

Extended examples for common integration patterns.

**Table of Contents**

- [Complete Data Migration from YNAB](#complete-data-migration-from-ynab)
- [Bank CSV Importer](#bank-csv-importer)
- [Recurring Transaction Report](#recurring-transaction-report)
- [Category Spending Analysis](#category-spending-analysis)
- [Account Reconciliation Helper](#account-reconciliation-helper)

## Complete Data Migration from YNAB

Full example showing how to migrate all data from YNAB to Actual.

```javascript
const api = require("@actual-app/api");
const fs = require("fs");

const CONFIG = {
  dataDir: "./actual-data",
  serverURL: "https://actual.example.com",
  password: process.env.ACTUAL_PASSWORD,
};

async function migrateFromYNAB(ynabExportPath) {
  const ynabData = JSON.parse(fs.readFileSync(ynabExportPath, "utf8"));

  await api.init(CONFIG);

  await api.runImport("YNAB-Import", async () => {
    // Map YNAB IDs to Actual IDs
    const accountMap = new Map();
    const categoryMap = new Map();
    const payeeMap = new Map();

    // Create accounts
    for (const ynabAcct of ynabData.accounts) {
      const actualId = await api.createAccount(
        {
          name: ynabAcct.name,
          type: mapAccountType(ynabAcct.type),
          closed: ynabAcct.closed,
        },
        ynabAcct.starting_balance,
      );
      accountMap.set(ynabAcct.id, actualId);
    }

    // Create payees (optional - can rely on auto-creation)
    for (const ynabPayee of ynabData.payees) {
      const actualId = await api.createPayee({ name: ynabPayee.name });
      payeeMap.set(ynabPayee.id, actualId);
    }

    // Create categories and groups
    for (const ynabGroup of ynabData.category_groups) {
      const groupId = await api.createCategoryGroup({
        name: ynabGroup.name,
        is_income: ynabGroup.is_income,
      });

      for (const ynabCat of ynabGroup.categories) {
        const catId = await api.createCategory({
          name: ynabCat.name,
          group_id: groupId,
          is_income: ynabCat.is_income,
        });
        categoryMap.set(ynabCat.id, catId);
      }
    }

    // Add transactions to each account
    for (const ynabAcct of ynabData.accounts) {
      const actualAcctId = accountMap.get(ynabAcct.id);
      const transactions = ynabAcct.transactions.map((t) => ({
        date: t.date,
        amount: api.utils.amountToInteger(t.amount / 1000), // YNAB uses milliunits
        payee_name: t.payee_name || t.memo?.split(" ")[0] || "Unknown",
        category: categoryMap.get(t.category_id),
        notes: t.memo,
        cleared: t.cleared === "cleared",
      }));

      await api.addTransactions(actualAcctId, transactions);
    }

    // Import budget amounts for current month
    const now = new Date();
    const monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;

    await api.batchBudgetUpdates(async () => {
      for (const ynabCat of ynabData.categories) {
        const actualCatId = categoryMap.get(ynabCat.id);
        if (actualCatId && ynabCat.budgeted) {
          await api.setBudgetAmount(
            monthStr,
            actualCatId,
            api.utils.amountToInteger(ynabCat.budgeted / 1000),
          );
        }
      }
    });
  });

  await api.shutdown();
}

function mapAccountType(ynabType) {
  const mapping = {
    checking: "checking",
    savings: "savings",
    creditCard: "credit",
    cash: "other",
    lineOfCredit: "debt",
    mortgage: "mortgage",
    autoLoan: "debt",
    studentLoan: "debt",
    personalLoan: "debt",
    medicalDebt: "debt",
    otherDebt: "debt",
  };
  return mapping[ynabType] || "other";
}
```

## Bank CSV Importer

Import transactions from a bank CSV export with proper deduplication.

```javascript
const api = require("@actual-app/api");
const fs = require("fs");
const { parse } = require("csv-parse/sync");

async function importBankCSV(accountId, csvPath, options = {}) {
  const {
    dateColumn = "Date",
    amountColumn = "Amount",
    payeeColumn = "Description",
    dateFormat = "YYYY-MM-DD",
  } = options;

  const csvData = fs.readFileSync(csvPath, "utf8");
  const records = parse(csvData, { columns: true, skip_empty_lines: true });

  await api.init({ dataDir: "./actual-data" });
  await api.loadBudget("my-budget");

  const transactions = records.map((row, index) => {
    const amount = parseFloat(row[amountColumn]);
    const date = parseDate(row[dateColumn], dateFormat);

    return {
      date,
      amount: api.utils.amountToInteger(amount),
      payee_name: row[payeeColumn]?.trim() || "Unknown",
      imported_id: generateImportId(row, index),
      cleared: true,
    };
  });

  const result = await api.importTransactions(accountId, transactions);
  console.log(
    `Imported: ${result.added.length} added, ${result.updated.length} updated`,
  );

  if (result.errors.length > 0) {
    console.error("Errors:", result.errors);
  }

  await api.shutdown();
  return result;
}

function parseDate(dateStr, format) {
  // Simple YYYY-MM-DD parser - extend as needed
  if (format === "YYYY-MM-DD") return dateStr;
  if (format === "MM/DD/YYYY") {
    const [m, d, y] = dateStr.split("/");
    return `${y}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
  }
  return dateStr;
}

function generateImportId(row, index) {
  // Generate unique ID based on row content
  const hash = require("crypto")
    .createHash("md5")
    .update(JSON.stringify(row))
    .digest("hex")
    .slice(0, 16);
  return `csv-${hash}`;
}
```

## Recurring Transaction Report

Find and report on scheduled/recurring transactions.

```javascript
const api = require("@actual-app/api");

async function generateRecurringReport() {
  await api.init({ dataDir: "./actual-data" });
  await api.loadBudget("my-budget");

  const schedules = await api.getSchedules();
  const accounts = await api.getAccounts();
  const payees = await api.getPayees();
  const categories = await api.getCategories();

  const accountMap = Object.fromEntries(accounts.map((a) => [a.id, a]));
  const payeeMap = Object.fromEntries(payees.map((p) => [p.id, p]));
  const categoryMap = Object.fromEntries(categories.map((c) => [c.id, c]));

  const report = schedules.map((s) => ({
    name: s.name,
    payee: payeeMap[s.payee]?.name || "Unknown",
    account: accountMap[s.account]?.name || "Unknown",
    category: categoryMap[s.category]?.name || "Uncategorized",
    amount: api.utils.integerToAmount(s.amount),
    nextDue: s.date,
    repeats: formatRepetition(s.repeats),
    autoPosts: s.posts_transaction,
    completed: s.completed,
  }));

  console.table(report);
  await api.shutdown();
  return report;
}

function formatRepetition(repeats) {
  if (!repeats) return "One-time";
  const { frequency, interval = 1 } = repeats;
  if (interval === 1) return frequency;
  return `Every ${interval} ${frequency}s`;
}
```

## Category Spending Analysis

Analyze spending by category for a date range.

```javascript
const api = require("@actual-app/api");

async function analyzeCategorySpending(startDate, endDate) {
  await api.init({ dataDir: "./actual-data" });
  await api.loadBudget("my-budget");

  const accounts = await api.getAccounts();
  const categories = await api.getCategories();
  const categoryMap = Object.fromEntries(categories.map((c) => [c.id, c.name]));

  const spending = {};

  for (const account of accounts) {
    if (account.closed || account.offbudget) continue;

    const transactions = await api.getTransactions(
      account.id,
      startDate,
      endDate,
    );

    for (const t of transactions) {
      if (t.amount >= 0) continue; // Skip income

      const catName = categoryMap[t.category] || "Uncategorized";
      spending[catName] = (spending[catName] || 0) + t.amount;
    }
  }

  // Sort by spending amount
  const sorted = Object.entries(spending)
    .map(([category, amount]) => ({
      category,
      amount: api.utils.integerToAmount(amount),
      percentage: 0, // Calculated below
    }))
    .sort((a, b) => a.amount - b.amount);

  const total = sorted.reduce((sum, s) => sum + s.amount, 0);
  sorted.forEach((s) => (s.percentage = ((s.amount / total) * 100).toFixed(1)));

  console.log(`\nSpending Analysis: ${startDate} to ${endDate}`);
  console.table(sorted);

  await api.shutdown();
  return sorted;
}
```

## Account Reconciliation Helper

Find uncleared transactions and calculate expected balances.

```javascript
const api = require("@actual-app/api");

async function reconciliationHelper(
  accountId,
  statementBalance,
  statementDate,
) {
  await api.init({ dataDir: "./actual-data" });
  await api.loadBudget("my-budget");

  const transactions = await api.getTransactions(
    accountId,
    "2020-01-01",
    statementDate,
  );

  const uncleared = transactions.filter((t) => !t.cleared);
  const cleared = transactions.filter((t) => t.cleared);

  const unclearedTotal = uncleared.reduce((sum, t) => sum + t.amount, 0);
  const clearedBalance = cleared.reduce((sum, t) => sum + t.amount, 0);

  const actualBalance = await api.getAccountBalance(
    accountId,
    new Date(statementDate),
  );
  const expectedBalance = clearedBalance;
  const difference =
    statementBalance - api.utils.integerToAmount(expectedBalance);

  console.log(`\nAccount Reconciliation Report`);
  console.log(`Statement Balance: $${statementBalance.toFixed(2)}`);
  console.log(
    `Actual Balance: $${api.utils.integerToAmount(actualBalance).toFixed(2)}`,
  );
  console.log(`Difference: $${difference.toFixed(2)}`);
  console.log(`\nUncleared Transactions (${uncleared.length}):`);
  console.table(
    uncleared.map((t) => ({
      date: t.date,
      payee: t.payee_name || "Unknown",
      amount: api.utils.integerToAmount(t.amount),
      notes: t.notes || "",
    })),
  );

  await api.shutdown();
  return { difference, uncleared, expectedBalance };
}
```

## Error Handling Pattern

Robust error handling with cleanup:

```javascript
const api = require("@actual-app/api");

class ActualClient {
  constructor(config) {
    this.config = config;
    this.connected = false;
  }

  async connect() {
    await api.init(this.config);
    this.connected = true;
  }

  async disconnect() {
    if (this.connected) {
      await api.shutdown();
      this.connected = false;
    }
  }

  async withConnection(callback) {
    try {
      await this.connect();
      return await callback(api);
    } catch (error) {
      console.error("Actual API Error:", error.message);
      throw error;
    } finally {
      await this.disconnect();
    }
  }
}

// Usage
const client = new ActualClient({
  dataDir: "./actual-data",
  serverURL: "https://actual.example.com",
  password: process.env.ACTUAL_PASSWORD,
});

async function safeOperation() {
  return client.withConnection(async (api) => {
    await api.downloadBudget("my-sync-id");
    const accounts = await api.getAccounts();
    // ... operations
    return accounts;
  });
}
```
