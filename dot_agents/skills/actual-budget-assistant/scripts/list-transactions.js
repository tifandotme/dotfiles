#!/usr/bin/env node

import {
  loadActual,
  checkEnv,
  parseDateRange,
  findAccountByName,
  formatAmount,
} from "./utils.js";

function parseArgs() {
  const args = {};
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith("--account=")) {
      args.account = arg.split("=")[1];
    } else if (arg.startsWith("--account-id=")) {
      args.accountId = arg.split("=")[1];
    } else if (arg.startsWith("--start=")) {
      args.startDate = arg.split("=")[1];
    } else if (arg.startsWith("--end=")) {
      args.endDate = arg.split("=")[1];
    } else if (arg.startsWith("--date=")) {
      args.dateRange = arg.split("=")[1];
    } else if (arg.startsWith("--limit=")) {
      args.limit = parseInt(arg.split("=")[1], 10);
    } else if (arg === "--json") {
      args.json = true;
    } else if (arg === "--help") {
      args.help = true;
    }
  }
  return args;
}

function showHelp() {
  console.log(`Usage: list-transactions.js [options]

Options:
  --account=NAME         Filter by account name (fuzzy match)
  --account-id=ID        Filter by account ID
  --date=RANGE           Date range (e.g., "last january 2026", "january 2026", "2026-01", "last month")
  --start=YYYY-MM-DD     Start date
  --end=YYYY-MM-DD       End date
  --limit=N              Limit results to N transactions
  --json                 Output as JSON
  --help                 Show this help

Examples:
  list-transactions.js --account="BCA" --date="last january 2026"
  list-transactions.js --account-id=abc-123 --start=2026-01-01 --end=2026-01-31
  list-transactions.js --date="last month" --limit=50
`);
}

async function main() {
  const args = parseArgs();

  if (args.help) {
    showHelp();
    process.exit(0);
  }

  checkEnv();

  const { api, shutdown } = await loadActual();

  try {
    let accountId = args.accountId;
    let accountName = null;

    // Resolve account by name if provided
    if (args.account && !accountId) {
      const account = await findAccountByName(api, args.account);
      if (!account) {
        const allAccounts = await api.getAccounts();
        const available = allAccounts
          .filter((a) => !a.closed)
          .map((a) => a.name)
          .join(", ");
        console.error(`Error: Account "${args.account}" not found.`);
        console.error(`Available accounts: ${available}`);
        process.exit(1);
      }
      accountId = account.id;
      accountName = account.name;
    }

    // Resolve date range
    let startDate = args.startDate;
    let endDate = args.endDate;

    if (args.dateRange) {
      const range = parseDateRange(args.dateRange);
      startDate = range.start;
      endDate = range.end;
    }

    // Fetch transactions
    const transactions = await api.getTransactions(
      accountId,
      startDate,
      endDate,
    );

    // Apply limit
    const limited = args.limit
      ? transactions.slice(0, args.limit)
      : transactions;

    if (args.json) {
      console.log(JSON.stringify(limited, null, 2));
    } else {
      // Header
      console.log("Transactions:");
      if (accountName) {
        console.log(`Account: ${accountName}`);
      }
      if (startDate && endDate) {
        console.log(`Date range: ${startDate} to ${endDate}`);
      } else if (accountId) {
        console.log("Date range: All time");
      }
      console.log("─".repeat(100));

      if (limited.length === 0) {
        console.log("No transactions found.");
      } else {
        console.log(
          `${"Date".padEnd(12)} ${"Payee".padEnd(25)} ${"Category".padEnd(20)} ${"Amount".padStart(12)} ${"Notes".padEnd(20)}`,
        );
        console.log("─".repeat(100));

        for (const t of limited) {
          const date = t.date;
          const payee = (t.payee_name || t.imported_payee || "-")
            .slice(0, 24)
            .padEnd(25);
          const category = (t.category_name || "-").slice(0, 19).padEnd(20);
          const amount = formatAmount(t.amount).padStart(12);
          const notes = (t.notes || "").slice(0, 19).padEnd(20);
          console.log(
            `${date.padEnd(12)} ${payee} ${category} ${amount} ${notes}`,
          );
        }
      }

      console.log("─".repeat(100));
      console.log(`Total: ${limited.length} transactions`);
    }
  } finally {
    await shutdown();
  }
}

main();
