#!/usr/bin/env node

import { getApiPath } from './utils.js';
import { existsSync, mkdirSync } from "fs";
import { homedir } from "os";
import path from "path";

async function main() {
  const apiPath = getApiPath();
  if (!apiPath) {
    console.error("Error: @actual-app/api not found.");
    console.error("Install it: npm install -g @actual-app/api");
    process.exit(1);
  }

  const api = await import(apiPath);

  const serverURL = process.env.ACTUAL_SERVER_URL;
  const password = process.env.ACTUAL_PASSWORD;
  const syncId = process.env.ACTUAL_SYNC_ID;

  if (!serverURL || !password || !syncId) {
    console.error("Error: Server credentials required.");
    console.error("\nSet these environment variables:");
    console.error("  export ACTUAL_SERVER_URL=https://actual.example.com");
    console.error("  export ACTUAL_PASSWORD=yourpassword");
    console.error("  export ACTUAL_SYNC_ID=your-sync-id");
    process.exit(1);
  }

  const tempDir = path.join(homedir(), ".cache/actual-budget-assistant");
  if (!existsSync(tempDir)) {
    mkdirSync(tempDir, { recursive: true });
  }

  if (process.env.ACTUAL_ALLOW_SELF_SIGNED_CERTS === "true") {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
  }

  try {
    console.log("Initializing Actual Budget API...");
    await api.init({
      dataDir: tempDir,
      serverURL,
      password,
    });

    console.log("Downloading budget...");
    await api.downloadBudget(syncId);

    console.log("✓ Budget downloaded successfully!");
    console.log(`Cache location: ${tempDir}`);

    // downloadBudget already loaded the budget, just verify it works
    const accounts = await api.getAccounts();
    console.log(`\nFound ${accounts.length} accounts:`);
    for (const acc of accounts.slice(0, 5)) {
      console.log(`  - ${acc.name}`);
    }
    if (accounts.length > 5) {
      console.log(`  ... and ${accounts.length - 5} more`);
    }

    await api.shutdown();
  } catch (err) {
    console.error(`[Error] ${err.message}`);
    console.error(err.stack);
    process.exit(1);
  }
}

main();
