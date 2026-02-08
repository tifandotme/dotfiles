#!/usr/bin/env node

import { loadActual, parseDateRange, findAccountByName, formatAmount, formatAsCsv } from './utils.js';

const COMMANDS = {
  accounts: {
    desc: 'List all accounts with balances',
    args: [],
    flags: ['json'],
  },
  categories: {
    desc: 'List budget categories',
    args: [],
    flags: ['json'],
  },
  balance: {
    desc: 'Get account balance(s)',
    args: [],
    flags: ['account-id', 'json'],
  },
  transactions: {
    desc: 'Query transactions',
    args: ['start', 'end'],
    flags: ['account-id', 'limit', 'json', 'csv'],
  },
};

function parseArgs(argv) {
  const args = { _command: null, flags: {} };
  
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    
    if (arg.startsWith('--')) {
      const [key, val] = arg.split('=');
      const flagName = key.slice(2);
      args.flags[flagName] = val !== undefined ? val : true;
    } else if (!args._command) {
      args._command = arg;
    }
  }
  
  return args;
}

function showHelp() {
  console.log(`Usage: actual-cli.js <command> [options]

Commands:
  accounts              List all accounts with balances
  categories            List budget categories
  balance               Get balance (all accounts or --account-id)
  transactions            List transactions (requires --start and --end)

Global Options:
  --json                Output as JSON

Command Options:
  balance:
    --account-id=ID     Specific account (omit for all)

  transactions:
    --account-id=ID     Filter by account
    --start=YYYY-MM-DD  Start date (required, ISO 8601)
    --end=YYYY-MM-DD    End date (required, ISO 8601)
    --limit=N           Limit results
    --csv               Output as CSV

Examples:
  actual-cli.js accounts
  actual-cli.js balance --account-id=abc-123
  actual-cli.js transactions --start=2026-01-01 --end=2026-01-31
  actual-cli.js transactions --account-id=abc-123 --start=2026-01-01 --end=2026-01-31 --csv

Note: Claude resolves natural language (e.g., "last month", "BCA") to
structured values before calling this script.
`);
}

function validateCommand(command, args) {
  if (!COMMANDS[command]) {
    console.error(`Error: Unknown command "${command}"`);
    showHelp();
    process.exit(1);
  }
  
  const spec = COMMANDS[command];
  
  for (const arg of spec.args) {
    if (!args.flags[arg]) {
      console.error(`Error: Missing required argument --${arg}`);
      showHelp();
      process.exit(1);
    }
  }
  
  // Validate ISO dates if present
  const isoDateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (args.flags.start && !isoDateRegex.test(args.flags.start)) {
    console.error(`Error: --start must be ISO 8601 format (YYYY-MM-DD)`);
    process.exit(1);
  }
  if (args.flags.end && !isoDateRegex.test(args.flags.end)) {
    console.error(`Error: --end must be ISO 8601 format (YYYY-MM-DD)`);
    process.exit(1);
  }
}

async function cmdAccounts(api, flags) {
  const accounts = await api.getAccounts();
  const filtered = accounts.filter(a => !a.closed);
  
  if (flags.json) {
    console.log(JSON.stringify(filtered, null, 2));
    return;
  }
  
  console.log('Accounts:');
  console.log('─'.repeat(60));
  for (const acc of filtered) {
    const balance = await api.getAccountBalance(acc.id);
    const formatted = formatAmount(balance).padStart(18);
    console.log(`${acc.name.padEnd(30)} ${formatted}`);
  }
  console.log('─'.repeat(60));
  const total = filtered.reduce((sum, a) => sum + (a.balance || 0), 0);
  console.log(`${'Total'.padEnd(30)} ${formatAmount(total).padStart(18)}`);
}

async function cmdCategories(api, flags) {
  const groups = await api.getCategoryGroups();
  
  if (flags.json) {
    console.log(JSON.stringify(groups, null, 2));
    return;
  }
  
  console.log('Categories:');
  console.log('─'.repeat(60));
  for (const group of groups) {
    const label = group.is_income ? '[Income]' : '[Expense]';
    console.log(`\n${group.name} ${label}`);
    if (group.categories?.length) {
      for (const cat of group.categories) {
        const hidden = cat.hidden ? '(hidden)' : '';
        console.log(`  • ${cat.name} ${hidden}`);
      }
    }
  }
}

async function cmdBalance(api, flags) {
  let accounts = [];
  
  if (flags['account-id']) {
    const all = await api.getAccounts();
    const acc = all.find(a => a.id === flags['account-id']);
    if (acc) accounts = [acc];
  } else {
    accounts = (await api.getAccounts()).filter(a => !a.closed);
  }
  
  if (accounts.length === 0) {
    console.log('No accounts found.');
    return;
  }
  
  const results = [];
  for (const acc of accounts) {
    const balance = await api.getAccountBalance(acc.id);
    results.push({ id: acc.id, name: acc.name, balance, formatted: formatAmount(balance) });
  }
  
  if (flags.json) {
    console.log(JSON.stringify(results, null, 2));
    return;
  }
  
  console.log('Account Balances:');
  console.log('─'.repeat(50));
  for (const r of results) {
    console.log(`${r.name.padEnd(30)} ${r.formatted.padStart(18)}`);
  }
  console.log('─'.repeat(50));
  const total = results.reduce((sum, r) => sum + r.balance, 0);
  console.log(`${'Total'.padEnd(30)} ${formatAmount(total).padStart(18)}`);
}

async function cmdTransactions(api, flags) {
  const accountId = flags['account-id'] || null;
  const limit = flags.limit ? parseInt(flags.limit, 10) : null;
  
  let accountName = null;
  if (accountId) {
    const accounts = await api.getAccounts();
    const acc = accounts.find(a => a.id === accountId);
    accountName = acc ? acc.name : accountId;
  }
  
  const transactions = await api.getTransactions(accountId, flags.start, flags.end);
  const limited = limit ? transactions.slice(0, limit) : transactions;
  
  if (flags.csv) {
    console.log(formatAsCsv(limited));
    return;
  }
  
  if (flags.json) {
    console.log(JSON.stringify(limited, null, 2));
    return;
  }
  
  console.log('Transactions:');
  if (accountName) console.log(`Account: ${accountName}`);
  console.log(`Date range: ${flags.start} to ${flags.end}`);
  console.log('─'.repeat(100));
  
  if (limited.length === 0) {
    console.log('No transactions found.');
  } else {
    console.log(`${'Date'.padEnd(12)} ${'Payee'.padEnd(25)} ${'Category'.padEnd(20)} ${'Amount'.padStart(12)} ${'Notes'.padEnd(20)}`);
    console.log('─'.repeat(100));
    
    for (const t of limited) {
      const date = t.date;
      const payee = (t.payee_name || t.imported_payee || '-').slice(0, 24).padEnd(25);
      const category = (t.category_name || '-').slice(0, 19).padEnd(20);
      const amount = formatAmount(t.amount).padStart(12);
      const notes = (t.notes || '').slice(0, 19).padEnd(20);
      console.log(`${date.padEnd(12)} ${payee} ${category} ${amount} ${notes}`);
    }
  }
  
  console.log('─'.repeat(100));
  console.log(`Total: ${limited.length} transactions`);
}

async function main() {
  const args = parseArgs(process.argv);
  
  if (!args._command || args.flags.help) {
    showHelp();
    process.exit(args.flags.help ? 0 : 1);
  }
  
  validateCommand(args._command, args);
  
  const { api, shutdown } = await loadActual();
  
  try {
    switch (args._command) {
      case 'accounts':
        await cmdAccounts(api, args.flags);
        break;
      case 'categories':
        await cmdCategories(api, args.flags);
        break;
      case 'balance':
        await cmdBalance(api, args.flags);
        break;
      case 'transactions':
        await cmdTransactions(api, args.flags);
        break;
    }
  } finally {
    await shutdown();
  }
}

main();
