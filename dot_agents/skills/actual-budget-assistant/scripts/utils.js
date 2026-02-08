import { createRequire } from "module";
import { execSync } from "child_process";
import { readdirSync, existsSync } from "fs";
import { homedir } from "os";
import path from "path";

const require = createRequire(import.meta.url);

function getGlobalNpmPath() {
  try {
    return execSync("npm root -g", { encoding: "utf8" }).trim();
  } catch {
    return null;
  }
}

function getApiPath() {
  try {
    const require = createRequire(import.meta.url);
    const localPath = require.resolve("@actual-app/api/package.json");
    return localPath.replace("/package.json", "/dist/index.js");
  } catch {
    const globalPath = getGlobalNpmPath();
    if (globalPath) {
      return `${globalPath}/@actual-app/api/dist/index.js`;
    }
    return null;
  }
}

function findLocalBudget() {
  const localShareDir = path.join(homedir(), ".local/share/actual");

  if (!existsSync(localShareDir)) {
    return null;
  }

  try {
    const entries = readdirSync(localShareDir, { withFileTypes: true });
    const budgetDir = entries.find(
      (e) => e.isDirectory() && e.name.match(/^My-Finances-[a-f0-9]+/i),
    );

    if (budgetDir) {
      return {
        dataDir: localShareDir,
        budgetId: budgetDir.name,
      };
    }
  } catch {
    return null;
  }

  return null;
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function syncWithRetry(api, maxRetries = 3) {
  let delay = 1000; // Start at 1s
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      await api.sync();
      return;
    } catch (err) {
      if (i === maxRetries - 1) {
        throw err;
      }
      console.error(`[Sync attempt ${i + 1}/${maxRetries} failed, retrying in ${delay}ms...]`);
      await sleep(delay);
      delay = Math.min(delay * 2, 30000);
    }
  }
}

export async function loadActual() {
  const apiPath = getApiPath();
  if (!apiPath) {
    console.error("Error: @actual-app/api not found.");
    console.error("Install it: npm install -g @actual-app/api");
    process.exit(1);
  }

  const api = await import(apiPath);
  
  const localBudget = findLocalBudget();
  
  const serverURL = process.env.ACTUAL_SERVER_URL;
  const password = process.env.ACTUAL_PASSWORD;
  const syncId = process.env.ACTUAL_SYNC_ID;
  
  if (!localBudget) {
    console.error("Error: No local budget found at ~/.local/share/actual/My-Finances-*");
    console.error("\nSetup:");
    console.error("  mkdir -p ~/.local/share/actual");
    console.error("  cp -r ~/path/to/budget/My-Finances-* ~/.local/share/actual/");
    process.exit(1);
  }
  
  if (!serverURL || !password || !syncId) {
    console.error("Error: Server credentials not configured.");
    console.error("\nRequired environment variables:");
    console.error("  export ACTUAL_SERVER_URL=https://actual.example.com");
    console.error("  export ACTUAL_PASSWORD=yourpassword");
    console.error("  export ACTUAL_SYNC_ID=your-sync-id");
    process.exit(1);
  }
  
  if (process.env.ACTUAL_ALLOW_SELF_SIGNED_CERTS === "true") {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
  }
  
  try {
    await api.init({
      dataDir: localBudget.dataDir,
      serverURL,
      password,
    });
    
    await api.loadBudget(localBudget.budgetId);
    await syncWithRetry(api, 3);
    console.error("[Synced] Budget updated from server");
    
    return {
      api,
      shutdown: () => api.shutdown(),
    };
  } catch (err) {
    console.error(`[Error] ${err.message}`);
    process.exit(1);
  }
}

export function parseDateRange(input) {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();

  // Handle "last january 2026" format
  const monthNames = [
    "january",
    "february",
    "march",
    "april",
    "may",
    "june",
    "july",
    "august",
    "september",
    "october",
    "november",
    "december",
  ];

  const lower = input.toLowerCase().trim();

  // last monthname year (e.g., "last january 2026")
  const lastMonthMatch = lower.match(/last\s+(\w+)\s+(\d{4})/);
  if (lastMonthMatch) {
    const monthIdx = monthNames.indexOf(lastMonthMatch[1].toLowerCase());
    const year = parseInt(lastMonthMatch[2], 10);
    if (monthIdx !== -1) {
      const start = new Date(year, monthIdx, 1);
      const end = new Date(year, monthIdx + 1, 0);
      return {
        start: formatDate(start),
        end: formatDate(end),
      };
    }
  }

  // monthname year (e.g., "january 2026")
  const monthYearMatch = lower.match(/^(\w+)\s+(\d{4})$/);
  if (monthYearMatch) {
    const monthIdx = monthNames.indexOf(monthYearMatch[1].toLowerCase());
    const year = parseInt(monthYearMatch[2], 10);
    if (monthIdx !== -1) {
      const start = new Date(year, monthIdx, 1);
      const end = new Date(year, monthIdx + 1, 0);
      return {
        start: formatDate(start),
        end: formatDate(end),
      };
    }
  }

  // "last month"
  if (lower === "last month") {
    const lastMonth = month === 0 ? 11 : month - 1;
    const lastMonthYear = month === 0 ? year - 1 : year;
    const start = new Date(lastMonthYear, lastMonth, 1);
    const end = new Date(lastMonthYear, lastMonth + 1, 0);
    return {
      start: formatDate(start),
      end: formatDate(end),
    };
  }

  // "this month"
  if (lower === "this month") {
    const start = new Date(year, month, 1);
    const end = new Date(year, month + 1, 0);
    return {
      start: formatDate(start),
      end: formatDate(end),
    };
  }

  // YYYY-MM-DD format
  if (/^\d{4}-\d{2}-\d{2}$/.test(lower)) {
    return { start: lower, end: lower };
  }

  // YYYY-MM format (full month)
  if (/^\d{4}-\d{2}$/.test(lower)) {
    const [y, m] = lower.split("-").map(Number);
    const start = new Date(y, m - 1, 1);
    const end = new Date(y, m, 0);
    return {
      start: formatDate(start),
      end: formatDate(end),
    };
  }

  throw new Error(
    `Cannot parse date: "${input}". Try formats like "last january 2026", "january 2026", "2026-01", or "2026-01-15"`,
  );
}

function formatDate(date) {
  return date.toISOString().split("T")[0];
}

export async function findAccountByName(api, name) {
  const accounts = await api.getAccounts();
  const lowerName = name.toLowerCase();

  // Exact match first
  let match = accounts.find(
    (a) => a.name.toLowerCase() === lowerName && !a.closed,
  );
  if (match) return match;

  // Partial match
  match = accounts.find(
    (a) => a.name.toLowerCase().includes(lowerName) && !a.closed,
  );
  if (match) return match;

  return null;
}

export function formatAmount(amount) {
  return (amount / 100).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
  });
}

export function formatAmountIDR(amount) {
  // Convert from cents to IDR (divide by 10 for IDR cents -> IDR)
  const idr = Math.abs(amount / 1000);
  return idr.toLocaleString("id-ID", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

export function formatAsCsv(transactions, options = {}) {
  const headers = options.headers || ["Date", "Description", "Type", "Amount (IDR)"];
  const lines = [headers.join(",")];

  for (const tx of transactions) {
    if (tx.is_child) continue; // Skip split children

    const date = tx.date;
    const desc = (tx.notes || "-").replace(/,/g, ";").replace(/"/g, '""');
    const type = tx.amount < 0 ? "Debit" : "Credit";
    const amount = formatAmountIDR(tx.amount);

    lines.push(`"${date}","${desc}",${type},${amount}`);
  }

  return lines.join("\n");
}
