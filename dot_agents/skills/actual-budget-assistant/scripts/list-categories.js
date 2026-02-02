#!/usr/bin/env node

import { loadActual, checkEnv } from './utils.js';

function parseArgs() {
  const args = {};
  for (const arg of process.argv.slice(2)) {
    if (arg === '--json') {
      args.json = true;
    } else if (arg === '--help') {
      args.help = true;
    }
  }
  return args;
}

function showHelp() {
  console.log(`Usage: list-categories.js [options]

Options:
  --json    Output as JSON
  --help    Show this help
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
    const groups = await api.getCategoryGroups();

    if (args.json) {
      console.log(JSON.stringify(groups, null, 2));
    } else {
      console.log('Categories:');
      console.log('─'.repeat(60));

      for (const group of groups) {
        const groupLabel = group.is_income ? '[Income]' : '[Expense]';
        console.log(`\n${group.name} ${groupLabel}`);

        if (group.categories && group.categories.length > 0) {
          for (const cat of group.categories) {
            const hidden = cat.hidden ? '(hidden)' : '';
            console.log(`  • ${cat.name} ${hidden}`);
          }
        }
      }
    }
  } finally {
    await shutdown();
  }
}

main();
