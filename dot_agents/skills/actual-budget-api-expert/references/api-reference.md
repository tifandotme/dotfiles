# Actual Budget API Reference

Complete reference for @actual-app/api methods and types.

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

## Budget Methods

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

```javascript
type ConditionOrAction = {
  field: string;
  op: string;
  value: any;
};
```

### Rule Type (RuleEntity)

| Field          | Type                  | Notes                     |
| -------------- | --------------------- | ------------------------- |
| `id`           | `id`                  | Auto-generated            |
| `stage`        | `'pre' \| 'post'`     | When rule applies         |
| `conditionsOp` | `'and' \| 'or'`       | How to combine conditions |
| `conditions`   | `ConditionOrAction[]` | Match conditions          |
| `actions`      | `ConditionOrAction[]` | Actions to apply          |
| `payee`        | `id`                  | Optional payee ID         |

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
createRule(rule: NewRuleEntity) → Promise<RuleEntity>
```

Returns created rule with generated `id`.

### updateRule

```javascript
updateRule(rule: RuleEntity) → Promise<RuleEntity>
```

Pass full rule object with `id` included. Returns updated rule.

### deleteRule

```javascript
deleteRule(id: string) → Promise<null>
```

## Schedule Methods

### RecurConfig Type

Configuration for recurring schedules.

```javascript
type RecurConfig = {
  frequency: 'daily' | 'weekly' | 'monthly' | 'yearly';
  interval?: number;                // Repeat every N frequency units
  patterns?: RecurPattern[];        // Specific day patterns
  skipWeekend?: boolean;            // Skip weekends
  start: string;                    // Start date (YYYY-MM-DD)
  endMode?: 'never' | 'after_n_occurrences' | 'on_date';
  endOccurrences?: number;          // Number of occurrences (if endMode: 'after_n_occurrences')
  endDate?: string;                 // End date (if endMode: 'on_date')
  weekendSolveMode?: 'before' | 'after';  // Move to before/after weekend
};

type RecurPattern = {
  value: number;
  type: 'SU' | 'MO' | 'TU' | 'WE' | 'TH' | 'FR' | 'SA' | 'day';
};
```

### Schedule Type (APIScheduleEntity)

| Field               | Type                                       | Notes                                    |
| ------------------- | ------------------------------------------ | ---------------------------------------- |
| `id`                | `id`                                       | Auto-generated (read-only)               |
| `name`              | `string`                                   | Schedule name                            |
| `payee`             | `id`                                       | Payee ID (optional, defaults null)       |
| `account`           | `id`                                       | Account ID (optional, defaults null)     |
| `amount`            | `amount \| { num1: number; num2: number }` | Amount or range                          |
| `amountOp`          | `'is' \| 'isapprox' \| 'isbetween'`        | Amount matching operator (required)      |
| `category`          | `id`                                       | Category ID                              |
| `date`              | `RecurConfig \| string`                    | Recurrence configuration                 |
| `posts_transaction` | `boolean`                                  | Auto-post flag                           |
| **Read-only:**      |                                            |                                          |
| `rule`              | `id`                                       | Underlying rule ID (system-populated)    |
| `next_date`         | `string`                                   | Next occurrence date (system-calculated) |
| `completed`         | `boolean`                                  | Completion status (system-managed)       |

### getSchedules

```javascript
getSchedules() → Promise<Schedule[]>
```

### createSchedule

```javascript
createSchedule(schedule: Omit<APIScheduleEntity, 'id' | 'rule' | 'next_date' | 'completed'>) → Promise<string>
```

Returns new schedule ID. Excludes read-only system fields (`rule`, `next_date`, `completed`).

### updateSchedule

```javascript
updateSchedule(id: string, fields: object, resetNextDate?: boolean) → Promise<string>
```

Returns schedule ID. Set `resetNextDate` to recalculate next occurrence date.

### deleteSchedule

```javascript
deleteSchedule(id: string) → Promise<null>
```

## Misc Methods

### getBudgets

```javascript
getBudgets() → Promise<APIFileEntity[]>
```

Returns list of all budget files (locally cached or on remote server).

```javascript
type APIFileEntity = {
  cloudFileId: string;
  id?: string;
  state?: 'remote';
  groupId?: string;
  name: string;
  encryptKeyId?: string;
  hasKey?: boolean;
  owner?: string;
  usersWithAccess?: string[];
};
```

### sync

```javascript
sync() → Promise<null>
```

Synchronizes locally cached budget files with server's copy.

### aqlQuery

```javascript
aqlQuery(query: Query) → Promise<any>
```

Runs an ActualQL query on the open budget. Replaces deprecated `runQuery`.

### q

```javascript
q(table: string) → Query
```

Creates a new query builder for ActualQL.

**Query Builder Methods:**

| Method             | Description                |
| ------------------ | -------------------------- |
| `filter(expr)`     | Add filter condition       |
| `unfilter(exprs?)` | Remove filter conditions   |
| `select(exprs)`    | Select fields to return    |
| `calculate(expr)`  | Calculate aggregate values |
| `groupBy(exprs)`   | Group results              |
| `orderBy(exprs)`   | Sort results               |
| `limit(num)`       | Limit number of results    |
| `offset(num)`      | Skip N results             |

### initConfig Type

Configuration object for `init()`:

**Base Config:**

```javascript
type BaseInitConfig = {
  dataDir?: string;      // Directory for local data storage
  verbose?: boolean;     // Enable verbose logging
};
```

**Password authentication:**

```javascript
type PasswordAuthConfig = BaseInitConfig & {
  serverURL: string;
  password: string;
  sessionToken?: never;
};
```

**Session token authentication:**

```javascript
type SessionTokenAuthConfig = BaseInitConfig & {
  serverURL: string;
  sessionToken: string;
  password?: never;
};
```

**Local-only mode (no server):**

```javascript
type NoServerConfig = BaseInitConfig & {
  serverURL?: undefined;
  password?: never;
  sessionToken?: never;
};
```

**Full type:**

```javascript
type InitConfig = PasswordAuthConfig | SessionTokenAuthConfig | NoServerConfig;
```

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

### runImport

```javascript
runImport(budgetName: string, func: () => Promise<void>) → Promise<void>
```

Creates a new budget file and runs a custom importer function to populate it.

### runBankSync

```javascript
runBankSync(accountId?: string) → Promise<null>
```

Sync transactions from linked bank accounts.

### runQuery

```javascript
runQuery(query: ActualQLQuery) → Promise<any>
```

Execute ActualQL query. **Deprecated:** Use `aqlQuery` instead.

### getBudgets

```javascript
getBudgets() → Promise<APIFileEntity[]>
```

Get available budgets.

### loadBudget

```javascript
loadBudget(syncId: string) → Promise<null>
```

Load budget file.

### downloadBudget

```javascript
downloadBudget(syncId: string, options?: { password?: string }) → Promise<null>
```

Download budget from sync server. `options.password` is required for encrypted budgets.

### batchBudgetUpdates

```javascript
batchBudgetUpdates(callback: () => Promise<void>) → Promise<null>
```

Batch multiple budget operations for performance.

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

### getAccountBalance

```javascript
getAccountBalance(id: string, cutoff?: Date) → Promise<number>
```

Get account balance up to a cutoff date.
