import { createRequire } from "module";
import { execSync } from "child_process";
import { pathToFileURL } from "url";

const require = createRequire(import.meta.url);

function getGlobalNpmPath() {
  try {
    return execSync("npm root -g", { encoding: "utf8" }).trim();
  } catch {
    return null;
  }
}

export function checkEnv() {
  const required = ["ACTUAL_SERVER_URL", "ACTUAL_PASSWORD", "ACTUAL_SYNC_ID"];
  const missing = required.filter((v) => !process.env[v]);

  if (missing.length > 0) {
    console.error("Error: Missing required environment variables:");
    for (const v of missing) {
      console.error(`  - ${v}`);
    }
    console.error("\nSet them as environment variables:");
    console.error("  export ACTUAL_SERVER_URL=https://actual.example.com");
    console.error("  export ACTUAL_PASSWORD=yourpassword");
    console.error("  export ACTUAL_SYNC_ID=your-sync-id");
    process.exit(1);
  }
}

export async function loadActual() {
  let apiModule;
  try {
    apiModule = await import("@actual-app/api");
  } catch (e) {
    if (e.code === "ERR_MODULE_NOT_FOUND") {
      // Try global npm install
      const globalPath = getGlobalNpmPath();
      if (globalPath) {
        try {
          const globalModulePath = `${globalPath}/@actual-app/api/dist/app/bundle.api.js`;
          apiModule = await import(pathToFileURL(globalModulePath).href);
        } catch {
          console.error("Error: @actual-app/api not found.");
          console.error("Install it: npm install -g @actual-app/api");
          process.exit(1);
        }
      } else {
        console.error("Error: @actual-app/api not found.");
        console.error("Install it: npm install -g @actual-app/api");
        process.exit(1);
      }
    } else {
      throw e;
    }
  }

  const api = apiModule.default || apiModule;

  await api.init({
    serverURL: process.env.ACTUAL_SERVER_URL,
    password: process.env.ACTUAL_PASSWORD,
  });

  await api.downloadBudget(process.env.ACTUAL_SYNC_ID);

  return {
    api,
    shutdown: () => api.shutdown(),
  };
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
