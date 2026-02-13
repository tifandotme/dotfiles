#!/usr/bin/env node

import { loadActual, formatAmount, findAccountByName } from './utils.js';
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const INNER_WORKER_ENV = 'ACTUAL_CLI_INNER_WORKER';

const CSV_HEADERS = ['Date', 'Payee', 'Notes', 'Category', 'Amount'];

// Noise patterns to filter from output (the Actual API is chatty)
const NOISE_PATTERNS = [
  /Warning: Setting the NODE_TLS_REJECT_UNAUTHORIZED/,
  /\(Use .*trace-warnings.*\)/,
  /\[Breadcrumb\]/,
  /Loaded spreadsheet from cache/,
  /Syncing since/,
  /Got messages from server/,
  /\[Cache .* old\]/,
  /\[Synced\]/,
  /\[Sync failed/,
  /message: '.*budget'/,
  /message: '.*spreadsheet'/,
  /category: 'server'/,
  /^\s*message: /,
  /^\s*category: /,
  /^\s*\}$/,
  /Performing transaction reconciliation/,
  /Debug data for the operations/,
  /transactionsStep\d+:/,
  /payee_name:/,
  /trans: \[Object\]/,
  /subtransactions:/,
  /match:/,
  /fuzzyDataset:/,
  /updatedPreview:/,
  /ignored:/,
  /imported_id:/,
  /imported_payee:/,
  /raw_synced_data:/,
  /^\s+id: '/,
  /^\s+payee: '/,
  /^\s+notes: '/,
  /^\s+cleared:/,
  /^\s+added: /,
  /^\s+updated: /,
];

function isNoise(line) {
  if (!line.trim()) return true;
  return NOISE_PATTERNS.some(p => p.test(line));
}

function filterOutput(data, outputFn) {
  const lines = data.toString().split('\n');
  for (const line of lines) {
    if (line && !isNoise(line)) {
      outputFn(line);
    }
  }
}

// Wrapper: spawn inner worker and filter its output
function runWrapped(args) {
  return new Promise((resolve) => {
    const child = spawn(
      process.execPath,
      [path.join(__dirname, 'actual-cli.js'), ...args],
      {
        stdio: ['inherit', 'pipe', 'pipe'],
        env: { ...process.env, [INNER_WORKER_ENV]: '1' },
      }
    );

    child.stdout.on('data', (data) => {
      filterOutput(data, console.log);
    });

    child.stderr.on('data', (data) => {
      filterOutput(data, console.error);
    });

    child.on('exit', (code) => {
      resolve(code || 0);
    });
  });
}

// Inner worker: run the actual logic
async function runInner() {
  const args = parseArgs(process.argv);

  if (!args.command || args.flags.help) {
    console.log(`Usage: actual-cli.js <command> [options]

Commands:
  transactions --start=DATE --end=DATE [--account=NAME] [--limit=N]
  balance [--account=NAME] [--all]
  import --data='[{date,account,payee,note,amount}]'

Options:
  --offline    Work from cache only (no server sync)
  --all        Show all accounts (including closed) for balance command

Examples:
  actual-cli.js transactions --start=2026-01-01 --end=2026-01-31
  actual-cli.js transactions --start=2026-01-01 --end=2026-01-31 --account=jago
  actual-cli.js balance --account=bca
  actual-cli.js balance --offline
  actual-cli.js balance --all
  actual-cli.js import --data='[{"date":"2026-02-08","account":"uuid","payee":"Starbucks","note":"Coffee","amount":450}]'`);
    process.exit(args.flags.help ? 0 : 1);
  }

  // Import command always syncs to server (no offline mode)
  const isOffline = args.command === 'import' ? false : args.flags.offline;
  const { api, shutdown } = await loadActual({
    offline: isOffline,
  });

  try {
    if (args.command === 'transactions') await cmdTransactions(api, args.flags);
    else if (args.command === 'balance') await cmdBalance(api, args.flags);
    else if (args.command === 'import') await cmdImport(api, args.flags);
    else {
      console.error(`Unknown command: ${args.command}`);
      process.exit(1);
    }
  } finally {
    await shutdown();
  }
}

function toCsv(transactions) {
  const lines = [CSV_HEADERS.join(',')];

  for (const t of transactions) {
    if (t.is_child) continue;

    const date = t.date;
    const payee = (t.payee_name || t.imported_payee || '-').replace(/,/g, ';').replace(/"/g, '""');
    const notes = (t.notes || '-').replace(/,/g, ';').replace(/"/g, '""');
    const category = (t.category_name || '-').replace(/,/g, ';').replace(/"/g, '""');
    const amount = formatAmount(t.amount);

    lines.push(`"${date}","${payee}","${notes}","${category}",${amount}`);
  }

  return lines.join('\n');
}

function parseArgs(argv) {
  const args = { command: null, flags: {} };

  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];

    if (arg.startsWith('--')) {
      const [key, val] = arg.split('=');
      args.flags[key.slice(2)] = val !== undefined ? val : true;
    } else if (!args.command) {
      args.command = arg;
    }
  }

  return args;
}

function validateIsoDate(date, name) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    console.error(`Error: ${name} must be YYYY-MM-DD format`);
    process.exit(1);
  }
}

async function resolveAccount(api, accountRef) {
  if (!accountRef) return null;

  // If it looks like a UUID, use it directly
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(accountRef)) {
    return accountRef;
  }

  // Otherwise, search by name
  const account = await findAccountByName(api, accountRef);
  if (!account) {
    console.error(`Error: Account "${accountRef}" not found`);
    process.exit(1);
  }
  return account.id;
}

async function cmdTransactions(api, flags) {
  validateIsoDate(flags.start, '--start');
  validateIsoDate(flags.end, '--end');

  const accountId = await resolveAccount(api, flags.account);
  const limit = flags.limit ? parseInt(flags.limit, 10) : null;

  // Fetch categories to map IDs to names
  const categoryGroups = await api.getCategoryGroups();
  const categoryMap = new Map();
  for (const group of categoryGroups) {
    for (const cat of group.categories || []) {
      categoryMap.set(cat.id, cat.name);
    }
  }

  const transactions = await api.getTransactions(accountId, flags.start, flags.end);

  // Enrich transactions with category names
  for (const t of transactions) {
    if (t.category && categoryMap.has(t.category)) {
      t.category_name = categoryMap.get(t.category);
    }
  }

  const limited = limit ? transactions.slice(0, limit) : transactions;

  console.log(toCsv(limited));
}

async function cmdBalance(api, flags) {
  const accountId = await resolveAccount(api, flags.account);

  const allAccounts = await api.getAccounts();
  const accounts = accountId
    ? allAccounts.filter(a => a.id === accountId)
    : allAccounts.filter(a => !a.closed || flags.all);

  const lines = ['UUID,Account,Balance,Status'];

  for (const acc of accounts) {
    const balance = await api.getAccountBalance(acc.id);
    const name = acc.name.replace(/,/g, ';').replace(/"/g, '""');
    const status = acc.closed ? 'closed' : 'open';
    lines.push(`"${acc.id}","${name}",${formatAmount(balance)},${status}`);
  }

  console.log(lines.join('\n'));
}

async function cmdImport(api, flags) {
  if (!flags.data) {
    console.error('Error: --data is required');
    process.exit(1);
  }

  let transactions;
  try {
    transactions = JSON.parse(flags.data);
  } catch (err) {
    console.error('Error: Invalid JSON in --data');
    process.exit(1);
  }

  if (!Array.isArray(transactions)) {
    console.error('Error: --data must be a JSON array');
    process.exit(1);
  }

  // Transform transactions
  const importTxns = transactions.map((t, idx) => {
    if (!t.date || !t.account || !t.amount) {
      console.error(`Error: Transaction ${idx} missing required field (date, account, or amount)`);
      process.exit(1);
    }

    return {
      date: t.date,
      account: t.account,
      amount: t.amount * 100,
      payee_name: t.payee || null,
      notes: t.note || null,
    };
  });

  // Group by account and import
  const byAccount = new Map();
  for (const t of importTxns) {
    if (!byAccount.has(t.account)) {
      byAccount.set(t.account, []);
    }
    byAccount.get(t.account).push(t);
  }

  let totalAdded = 0;
  let totalUpdated = 0;
  let totalErrors = 0;

  // Suppress console.log during import (Actual API is noisy)
  const originalLog = console.log;
  console.log = () => {};

  try {
    for (const [accountId, txns] of byAccount) {
      const result = await api.importTransactions(accountId, txns);
      totalAdded += result.added.length;
      totalUpdated += result.updated.length;
      totalErrors += result.errors.length;
    }
  } finally {
    console.log = originalLog;
  }

  console.log(JSON.stringify({
    added: totalAdded,
    updated: totalUpdated,
    errors: totalErrors
  }));
}

// Main entry: wrap unless already inner worker
if (process.env[INNER_WORKER_ENV]) {
  runInner();
} else {
  const args = process.argv.slice(2);
  runWrapped(args).then(code => process.exit(code));
}
