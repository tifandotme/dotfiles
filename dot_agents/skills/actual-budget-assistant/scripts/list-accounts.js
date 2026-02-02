#!/usr/bin/env node

import { loadActual, checkEnv } from './utils.js';

async function main() {
  checkEnv();

  const { api, shutdown } = await loadActual();

  try {
    const accounts = await api.getAccounts();

    // Filter out closed accounts by default
    const showClosed = process.argv.includes('--include-closed');
    const filtered = showClosed ? accounts : accounts.filter(a => !a.closed);

    // Format output
    const format = process.argv.find(arg => arg.startsWith('--format='))?.split('=')[1] || 'table';

    if (format === 'json') {
      console.log(JSON.stringify(filtered, null, 2));
    } else {
      console.log('Accounts:');
      console.log('─'.repeat(60));
      for (const acc of filtered) {
        const balance = await api.getAccountBalance(acc.id);
        const balanceFormatted = (balance / 100).toLocaleString('en-US', {
          style: 'currency',
          currency: 'USD'
        });
        const status = acc.closed ? '[CLOSED]' : '        ';
        console.log(`${acc.id}  ${status}  ${acc.name.padEnd(20)}  ${balanceFormatted}`);
      }
      console.log('─'.repeat(60));
      console.log('Use --include-closed to show closed accounts');
      console.log('Use --format=json for JSON output');
    }
  } finally {
    await shutdown();
  }
}

main();
