# Actual Budget API Reference

Complete reference for @actual-app/api methods and types.

**Table of Contents**

- [Types of Methods](#types-of-methods)
- [Primitives](#primitives)
- [Utility Functions](#utility-functions)
- [Connection Methods](#connection-methods)
- [Budget Methods](#budget-methods)
- [Transaction Methods](#transaction-methods)
- [Account Methods](#account-methods)
- [Category Methods](#category-methods)
- [Category Group Methods](#category-group-methods)
- [Payee Methods](#payee-methods)
- [Rule Methods](#rule-methods)
- [Schedule Methods](#schedule-methods)
- [Misc Methods](#misc-methods)
- [HTTPS Configuration](#https-configuration)

## Types of Methods

API methods are categorized into one of four types:

- `get` - Retrieve data
- `create` - Add new data
- `update` - Modify existing data
- `delete` - Remove data

Objects may have fields specific for a type of method. For example, the `payee` field of a `transaction` is only available in a `create` method. This field doesn't exist in objects returned from a `get` method (`payee_id` is used instead).

`id` is a special field. All objects have an `id` field. However, you don't need to specify an `id` in a `create` method; all `create` methods will return the created `id` back to you.

All `update` and `delete` methods take an `id` to specify the desired object. `update` takes the fields to update as a second argument — it does not take a full object.

## Primitives

| Name     | Type      | Notes                                                                                                                                                                                                    |
| -------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`     | `string`  | UUID                                                                                                                                                                                                     |
| `month`  | `string`  | `YYYY-MM`                                                                                                                                                                                                |
| `date`   | `string`  | `YYYY-MM-DD`                                                                                                                                                                                             |
| `amount` | `integer` | A currency amount is an integer representing the value without any decimal places. Usually it's `value * 100`, but it depends on your currency. For example, a USD amount of `$120.30` would be `12030`. |

## Utility Functions

### utils.amountToInteger

```javascript
utils.amountToInteger(amount: number) → number
```

Convert a currency amount (e.g., `123.45`) to the integer format Actual uses internally (`12345`).

```javascript
const amountInt = api.utils.amountToInteger(120.3); // 12030
```

### utils.integerToAmount

```javascript
utils.integerToAmount(amount: number) → number
```

Convert an integer amount from Actual (e.g., `12345`) to a floating point number (`123.45`).

```javascript
const amountFloat = api.utils.integerToAmount(12030); // 120.30
```

## Connection Methods

### getBudgetMonths

```javascript
getBudgetMonths() → Promise<string[]>
```

Returns array of month strings (YYYY-MM) that have budget data.

### getBudgetMonth

```javascript
getBudgetMonth(month: string) → Promise<BudgetMonth>
```

Get budget data for a specific month.

### setBudgetAmount

```javascript
setBudgetAmount(month: string, categoryId: string, amount: number) → Promise<null>
```

Set the budgeted amount for a category in a month.

### setBudgetCarryover

```javascript
setBudgetCarryover(month: string, categoryId: string, flag: boolean) → Promise<null>
```

Enable or disable carryover for a category.

### holdBudgetForNextMonth

```javascript
holdBudgetForNextMonth(month: string, amount: number) → Promise<null>
```

Hold funds for the next month.

### resetBudgetHold

```javascript
resetBudgetHold(month: string) → Promise<null>
```

Reset held funds for a month.

## Transaction Methods

### Transaction Type

| Field             | Type            | Required? | Notes                                              |
| ----------------- | --------------- | --------- | -------------------------------------------------- |
| `id`              | `id`            | no        | Auto-generated                                     |
| `account`         | `id`            | yes       | Account ID                                         |
| `date`            | `date`          | yes       | YYYY-MM-DD                                         |
| `amount`          | `amount`        | no        | Integer cents                                      |
| `payee`           | `id`            | no        | Create only: Payee ID                              |
| `payee_name`      | `string`        | no        | Create only: Creates payee if doesn't exist        |
| `imported_payee`  | `string`        | no        | Raw description from import                        |
| `category`        | `id`            | no        | Category ID                                        |
| `notes`           | `string`        | no        | Notes                                              |
| `imported_id`     | `string`        | no        | Unique ID from bank for dedup                      |
| `transfer_id`     | `string`        | no        | Internal: transaction ID on other side of transfer |
| `cleared`         | `boolean`       | no        | Cleared flag                                       |
| `subtransactions` | `Transaction[]` | no        | Get/Create only: Array for split transactions      |

### Split Transactions

Subtransactions only require `amount`. Optional fields: `category`, `notes`.

### addTransactions

```javascript
addTransactions(
  accountId: string,
  transactions: Transaction[],
  runTransfers?: boolean = false,
  learnCategories?: boolean = false
) → Promise<string[]>
```

Add raw transactions. Does NOT reconcile/avoid duplicates. Returns array of new transaction IDs.

Flags:

- `runTransfers`: Create transfers for transactions with transfer payee
- `learnCategories`: Update rules based on category field

### importTransactions

```javascript
importTransactions(
  accountId: string,
  transactions: Transaction[]
) → Promise<{ added: string[], updated: string[], errors: any[] }>
```

Import transactions with full reconcile behavior (deduplication, rules, transfers).

### getTransactions

```javascript
getTransactions(
  accountId: string,
  startDate: string,
  endDate: string
) → Promise<Transaction[]>
```

Get transactions in date range (inclusive).

### updateTransaction

```javascript
updateTransaction(id: string, fields: object) → Promise<null>
```

Update transaction fields.

### deleteTransaction

```javascript
deleteTransaction(id: string) → Promise<null>
```

Delete a transaction.

## Account Methods

### Account Type

| Field       | Type      | Required? | Notes                                                        |
| ----------- | --------- | --------- | ------------------------------------------------------------ |
| `id`        | `id`      | no        | Auto-generated                                               |
| `name`      | `string`  | yes       | Account name                                                 |
| `type`      | `string`  | no        | checking, savings, credit, investment, mortgage, debt, other |
| `offbudget` | `boolean` | no        | Defaults to false                                            |
| `closed`    | `boolean` | no        | Defaults to false                                            |

### getAccounts

```javascript
getAccounts() → Promise<Account[]>
```

### createAccount

```javascript
createAccount(account: Account, initialBalance?: number = 0) → Promise<string>
```

Returns new account ID.

### updateAccount

```javascript
updateAccount(id: string, fields: object) → Promise<null>
```

### closeAccount

```javascript
closeAccount(
  id: string,
  transferAccountId?: string,
  transferCategoryId?: string
) → Promise<null>
```

Close account. If balance is non-zero, must specify `transferAccountId`. If transferring to off-budget, optionally specify `transferCategoryId`.

### reopenAccount

```javascript
reopenAccount(id: string) → Promise<null>
```

### deleteAccount

```javascript
deleteAccount(id: string) → Promise<null>
```

### getAccountBalance

```javascript
getAccountBalance(id: string, cutoff?: Date) → Promise<number>
```

## Category Methods

### Category Type

| Field       | Type      | Required? | Notes             |
| ----------- | --------- | --------- | ----------------- |
| `id`        | `id`      | no        | Auto-generated    |
| `name`      | `string`  | yes       | Category name     |
| `group_id`  | `id`      | yes       | Category group ID |
| `is_income` | `boolean` | no        | Defaults to false |

### getCategories

```javascript
getCategories() → Promise<Category[]>
```

### createCategory

```javascript
createCategory(category: Category) → Promise<string>
```

Returns new category ID.

### updateCategory

```javascript
updateCategory(id: string, fields: object) → Promise<null>
```

### deleteCategory

```javascript
deleteCategory(id: string) → Promise<null>
```

## Category Group Methods

### Category Group Type

| Field        | Type         | Required? | Notes                         |
| ------------ | ------------ | --------- | ----------------------------- |
| `id`         | `id`         | no        | Auto-generated                |
| `name`       | `string`     | yes       | Group name                    |
| `is_income`  | `boolean`    | no        | Defaults to false             |
| `categories` | `Category[]` | no        | Get only: Categories in group |

### getCategoryGroups

```javascript
getCategoryGroups() → Promise<CategoryGroup[]>
```

### createCategoryGroup

```javascript
createCategoryGroup(group: CategoryGroup) → Promise<string>
```

Returns new group ID.

### updateCategoryGroup

```javascript
updateCategoryGroup(id: string, fields: object) → Promise<string>
```

### deleteCategoryGroup

```javascript
deleteCategoryGroup(id: string) → Promise<null>
```

## Payee Methods

### Payee Type

| Field           | Type      | Required? | Notes                                         |
| --------------- | --------- | --------- | --------------------------------------------- |
| `id`            | `id`      | no        | Auto-generated                                |
| `name`          | `string`  | yes       | Payee name                                    |
| `transfer_acct` | `id`      | no        | Account ID if this payee is a transfer target |
| `favorite`      | `boolean` | no        | Defaults to false                             |

### getPayees

```javascript
getPayees() → Promise<Payee[]>
```

### createPayee

```javascript
createPayee(payee: Payee) → Promise<string>
```

Returns new payee ID.

### updatePayee

```javascript
updatePayee(id: string, fields: object) → Promise<null>
```

### deletePayee

```javascript
deletePayee(id: string) → Promise<null>
```

### mergePayees

```javascript
mergePayees(targetId: string, sourceIds: string[]) → Promise<null>
```

Merge source payees into target payee.

## Rule Methods

### ConditionOrAction Type

Rules have conditions and actions that determine how transactions are processed.

### Rule Type

| Field        | Type                  | Notes             |
| ------------ | --------------------- | ----------------- |
| `id`         | `id`                  | Auto-generated    |
| `conditions` | `ConditionOrAction[]` | Match conditions  |
| `actions`    | `ConditionOrAction[]` | Actions to apply  |
| `payee`      | `id`                  | Optional payee ID |

### getRules

```javascript
getRules() → Promise<Rule[]>
```

### getPayeeRules

```javascript
getPayeeRules(payeeId: string) → Promise<Rule[]>
```

### createRule

```javascript
createRule(rule: Rule) → Promise<string>
```

### updateRule

```javascript
updateRule(id: string, fields: object) → Promise<null>
```

### deleteRule

```javascript
deleteRule(id: string) → Promise<null>
```

## Schedule Methods

### RecurConfig Type

Configuration for recurring schedules.

### Schedule Type

| Field               | Type          | Notes             |
| ------------------- | ------------- | ----------------- |
| `id`                | `id`          | Auto-generated    |
| `name`              | `string`      | Schedule name     |
| `payee`             | `id`          | Payee ID          |
| `account`           | `id`          | Account ID        |
| `amount`            | `amount`      | Amount            |
| `category`          | `id`          | Category ID       |
| `date`              | `date`        | Next due date     |
| `repeats`           | `RecurConfig` | Recurrence config |
| `completed`         | `boolean`     | Completion flag   |
| `posts_transaction` | `boolean`     | Auto-post flag    |

### getSchedules

```javascript
getSchedules() → Promise<Schedule[]>
```

### createSchedule

```javascript
createSchedule(schedule: Schedule) → Promise<string>
```

### updateSchedule

```javascript
updateSchedule(id: string, fields: object) → Promise<null>
```

### deleteSchedule

```javascript
deleteSchedule(id: string) → Promise<null>
```

## Misc Methods

### initConfig Type

Configuration object for `init()`:

| Field       | Type     | Notes                          |
| ----------- | -------- | ------------------------------ |
| `dataDir`   | `string` | Path to data directory         |
| `serverURL` | `string` | Optional: Sync server URL      |
| `password`  | `string` | Optional: Sync server password |

### init

```javascript
init(config: initConfig) → Promise<null>
```

### shutdown

```javascript
shutdown() → Promise<null>
```

### sync

```javascript
sync() → Promise<null>
```

Sync with server.

### runBankSync

```javascript
runBankSync(accountId?: string) → Promise<null>
```

Sync transactions from linked bank accounts.

### runImport

```javascript
runImport(accountId: string, filePath: string) → Promise<null>
```

Import transactions from file (OFX, QFX, CSV, etc.).

### getBudgets

```javascript
getBudgets() → Promise<BudgetFile[]>
```

Get available budgets.

### loadBudget

```javascript
loadBudget(budgetId: string) → Promise<null>
```

Load budget file.

### downloadBudget

```javascript
downloadBudget(syncId: string, password?: { password: string }) → Promise<null>
```

Download budget from sync server.

For end-to-end encrypted budgets, pass the encryption password as an object:

```javascript
// Standard download
await api.downloadBudget("sync-id");

// With end-to-end encryption
await api.downloadBudget("sync-id", { password: "encryption-password" });
```

### batchBudgetUpdates

```javascript
batchBudgetUpdates(callback: () => Promise<void>) → Promise<null>
```

Batch multiple budget operations for performance.

### runImport

```javascript
runImport(name: string, callback: () => Promise<void>) → Promise<null>
```

**Bulk import mode for data migrations.** Creates a new budget file and runs the callback with optimized performance.

Use this when migrating from other apps (YNAB, Mint, etc.). In this mode:

- A new budget file is always created
- Operations run faster than normal mode
- Use `addTransactions` (not `importTransactions`) to avoid deduplication/rules

```javascript
await api.runImport("My-YNAB-Import", async () => {
  for (const acct of ynabData.accounts) {
    const id = await api.createAccount(convertAccount(acct));
    await api.addTransactions(id, convertTransactions(acct.transactions));
  }
});
```

### runQuery

```javascript
runQuery(query: ActualQLQuery) → Promise<any>
```

Execute ActualQL query.

### getIDByName

```javascript
getIDByName(type: string, name: string) → Promise<string | null>
```

Look up ID by name for accounts, categories, payees, etc.

## HTTPS Configuration

When connecting to an Actual server using self-signed or custom CA certificates, additional Node.js configuration is required.

### Option 1: Trust Specific Certificate (Recommended)

Set the `NODE_EXTRA_CA_CERTS` environment variable to the path of your certificate file:

```bash
export NODE_EXTRA_CA_CERTS=/path/to/cert.pem
node your-script.js
```

### Option 2: Disable TLS Verification (Development Only)

**Warning:** Not recommended for production or when connecting to other endpoints.

```bash
export NODE_TLS_REJECT_UNAUTHORIZED=0
node your-script.js
```

### Option 3: OpenSSL Configuration

Add your certificate to the OpenSSL CA directory. This depends on your Node.js build configuration. See [Node.js OpenSSL Strategy](https://github.com/nodejs/TSC/blob/main/OpenSSL-Strategy.md) for details.
