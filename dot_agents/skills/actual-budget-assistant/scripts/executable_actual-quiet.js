#!/usr/bin/env node

// Wrapper that runs actual-cli.js and filters noisy stderr
import { spawn } from "child_process";
import { fileURLToPath } from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

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
  /message: '.*budget'/,  // Loading/Closing budget messages
  /message: '.*spreadsheet'/,  // loading/loaded spreadsheet
  /category: 'server'/,
  /^\s*message: /,
  /^\s*category: /,
  /^\s*\}$/,  // Lines with just }
  /^\s*\{[^}]*\}$/,  // Single-line objects like { message: ... }
];

function isNoise(line) {
  if (!line.trim()) return true;  // Skip empty lines
  return NOISE_PATTERNS.some(p => p.test(line));
}

const args = process.argv.slice(2);
const child = spawn("node", [path.join(__dirname, "actual-cli.js"), ...args], {
  stdio: ["inherit", "pipe", "pipe"],
  env: process.env,
});

// Filter both stdout and stderr
function filterStream(data, output) {
  const lines = data.toString().split("\n");
  for (const line of lines) {
    if (line && !isNoise(line)) {
      output(line);
    }
  }
}

child.stdout.on("data", (data) => {
  filterStream(data, console.log);
});

child.stderr.on("data", (data) => {
  filterStream(data, console.error);
});

child.on("exit", (code) => {
  process.exit(code || 0);
});
