#!/usr/bin/env node

/**
 * List all accounts in Actual Budget
 * Usage: node list-accounts.js
 */

const api = require('@actual-app/api');

async function main() {
  const dataDir = process.env.ACTUAL_DATA_DIR;
  if (!dataDir) {
    console.error('Error: ACTUAL_DATA_DIR environment variable is required');
    process.exit(1);
  }

  const config = {
    dataDir,
    serverURL: process.env.ACTUAL_SERVER_URL,
    password: process.env.ACTUAL_PASSWORD,
  };

  try {
    await api.init(config);

    const syncId = process.env.ACTUAL_SYNC_ID;
    if (syncId) {
      await api.downloadBudget(syncId);
    }

    const accounts = await api.getAccounts();

    console.log('Accounts:');
    console.log('');
    accounts.forEach(acc => {
      const type = acc.type || 'unknown';
      const status = acc.closed ? 'closed' : (acc.offbudget ? 'off-budget' : 'on-budget');
      console.log(`  ${acc.id} | ${acc.name} (${type}, ${status})`);
    });

    console.log('');
    console.log(`Total: ${accounts.length} accounts`);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  } finally {
    await api.shutdown();
  }
}

main();
