#!/usr/bin/env node

import { loadActual, checkEnv, findAccountByName, formatAmount } from './utils.js';

function parseArgs() {
  const args = {};
  for (const arg of process.argv.slice(2)) {
    if (arg.startsWith('--account=')) {
      args.account = arg.split('=')[1];
    } else if (arg.startsWith('--account-id=')) {
      args.accountId = arg.split('=')[1];
    } else if (arg === '--json') {
      args.json = true;
    } else if (arg === '--help') {
      args.help = true;
    }
  }
  return args;
}

function showHelp() {
  console.log(`Usage: get-balance.js [options]

Options:
  --account=NAME      Account name (fuzzy match)
  --account-id=ID     Account ID
  --json              Output as JSON
  --help              Show this help

Examples:
  get-balance.js --account="BCA"
  get-balance.js --account-id=abc-123 --json

Note: If no account specified, shows all accounts.
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
    let accounts = [];

    if (args.accountId) {
      const all = await api.getAccounts();
      const acc = all.find(a => a.id === args.accountId);
      if (acc) accounts = [acc];
    } else if (args.account) {
      const acc = await findAccountByName(api, args.account);
      if (acc) {
        accounts = [acc];
      } else {
        const all = await api.getAccounts();
        const available = all.filter(a => !a.closed).map(a => a.name).join(', ');
        console.error(`Error: Account "${args.account}" not found.`);
        console.error(`Available accounts: ${available}`);
        process.exit(1);
      }
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
      results.push({
        id: acc.id,
        name: acc.name,
        balance: balance,
        formattedBalance: formatAmount(balance)
      });
    }

    if (args.json) {
      console.log(JSON.stringify(results, null, 2));
    } else {
      console.log('Account Balances:');
      console.log('─'.repeat(50));
      for (const r of results) {
        console.log(`${r.name.padEnd(30)} ${r.formattedBalance.padStart(18)}`);
      }
      console.log('─'.repeat(50));
      const total = results.reduce((sum, r) => sum + r.balance, 0);
      console.log(`${'Total'.padEnd(30)} ${formatAmount(total).padStart(18)}`);
    }
  } finally {
    await shutdown();
  }
}

main();
