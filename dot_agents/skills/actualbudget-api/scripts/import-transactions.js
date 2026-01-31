#!/usr/bin/env node

/**
 * Import transactions into Actual Budget from JSON file
 * Usage: node import-transactions.js <account-id> <transactions.json>
 */

const api = require('@actual-app/api');
const fs = require('fs');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.error('Usage: node import-transactions.js <account-id> <transactions.json>');
    console.error('');
    console.error('Environment variables:');
    console.error('  ACTUAL_DATA_DIR    - Path to Actual data directory (required)');
    console.error('  ACTUAL_SERVER_URL  - Sync server URL (optional)');
    console.error('  ACTUAL_PASSWORD    - Sync server password (optional)');
    console.error('  ACTUAL_SYNC_ID     - Budget sync ID (optional, for download)');
    process.exit(1);
  }

  const [accountId, transactionsFile] = args;

  // Validate inputs
  if (!fs.existsSync(transactionsFile)) {
    console.error(`Error: File not found: ${transactionsFile}`);
    process.exit(1);
  }

  const dataDir = process.env.ACTUAL_DATA_DIR;
  if (!dataDir) {
    console.error('Error: ACTUAL_DATA_DIR environment variable is required');
    process.exit(1);
  }

  // Parse transactions
  let transactions;
  try {
    const content = fs.readFileSync(transactionsFile, 'utf-8');
    transactions = JSON.parse(content);
    if (!Array.isArray(transactions)) {
      transactions = [transactions];
    }
  } catch (err) {
    console.error(`Error parsing JSON: ${err.message}`);
    process.exit(1);
  }

  console.log(`Importing ${transactions.length} transaction(s) to account ${accountId}...`);

  // Initialize API
  const config = {
    dataDir,
    serverURL: process.env.ACTUAL_SERVER_URL,
    password: process.env.ACTUAL_PASSWORD,
  };

  try {
    await api.init(config);

    // Download budget if sync ID provided
    const syncId = process.env.ACTUAL_SYNC_ID;
    if (syncId) {
      console.log(`Downloading budget ${syncId}...`);
      await api.downloadBudget(syncId);
    }

    // Import transactions
    const result = await api.importTransactions(accountId, transactions);

    console.log('');
    console.log('Import complete:');
    console.log(`  Added:   ${result.added.length}`);
    console.log(`  Updated: ${result.updated.length}`);
    console.log(`  Errors:  ${result.errors.length}`);

    if (result.errors.length > 0) {
      console.error('');
      console.error('Errors:');
      result.errors.forEach(err => console.error(`  - ${err}`));
      process.exit(1);
    }

    // Sync if we downloaded
    if (syncId) {
      console.log('Syncing changes to server...');
      await api.sync();
    }

    process.exit(0);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    process.exit(1);
  } finally {
    await api.shutdown();
  }
}

main();
