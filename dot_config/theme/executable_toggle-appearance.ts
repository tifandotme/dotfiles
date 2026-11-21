#!/usr/bin/env bun

import { $ } from "bun";
import { join } from "node:path";

async function replaceRequired(path: string, pattern: RegExp, replacement: string) {
  const current = await Bun.file(path).text();

  if (!pattern.test(current)) {
    throw new Error(`No matching content to update in ${path}`);
  }

  const next = current.replace(pattern, replacement);

  if (next !== current) {
    await Bun.write(path, next);
  }
}

async function updateSourceFiles(isDark: boolean) {
  const root = (await $`chezmoi source-path`.text()).trim();
  const gitConfig = join(root, "dot_config", "git", "config.tmpl");

  await replaceRequired(
    gitConfig,
    /(\[delta\]\n\s*light = )(true|false)/,
    `$1${isDark ? "false" : "true"}`,
  );
}

async function main() {
  const home = Bun.env.HOME;

  if (!home) {
    throw new Error("HOME is not set");
  }

  const appearance = 'tell application "System Events" to tell appearance preferences to';
  const isDark = (await $`osascript -e ${`${appearance} get dark mode`}`.text()).trim() !== "true";
  await updateSourceFiles(isDark);

  const targets = ["git/config"].map((path) => join(home, ".config", path));
  await $`chezmoi apply --force ${targets} > /dev/null`;
  await $`osascript -e ${`${appearance} set dark mode to ${isDark}`} > /dev/null`;
  await Bun.write(join(home, ".config", "theme", "appearance.changed"), `${Date.now()}\n`);

  console.log(`Appearance set to ${isDark ? "dark" : "light"}`);
}

await main();
