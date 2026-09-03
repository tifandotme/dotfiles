#!/usr/bin/env bun

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

function run(command: string, args: string[], options: { quiet?: boolean } = {}) {
  try {
    return execFileSync(command, args, {
      encoding: "utf8",
      stdio: options.quiet ? ["ignore", "pipe", "pipe"] : ["inherit", "pipe", "inherit"],
    }).trim();
  } catch {
    throw new Error(`Command failed: ${command} ${args.join(" ")}`);
  }
}

function optionalRun(command: string, args: string[]) {
  try {
    execFileSync(command, args, { stdio: "ignore" });
  } catch {
    // Optional live reload failed. The source files were still updated.
  }
}

function sourceRoot() {
  return run("chezmoi", ["source-path"], { quiet: true });
}

function replaceRequired(path: string, pattern: RegExp, replacement: string) {
  const current = readFileSync(path, "utf8");

  if (!pattern.test(current)) {
    throw new Error(`No matching content to update in ${path}`);
  }

  const next = current.replace(pattern, replacement);

  if (next !== current) {
    writeFileSync(path, next);
  }
}

function getMacAppearance() {
  return (
    run(
      "osascript",
      ["-e", 'tell application "System Events" to tell appearance preferences to get dark mode'],
      { quiet: true },
    ) === "true"
  );
}

function setMacAppearance(isDark: boolean) {
  run("osascript", [
    "-e",
    `tell application "System Events" to tell appearance preferences to set dark mode to ${isDark ? "true" : "false"}`,
  ]);
}

function updateSourceFiles(isDark: boolean) {
  const root = sourceRoot();
  const gitConfig = join(root, "dot_config", "git", "config.tmpl");
  const glowConfig = join(root, "dot_config", "glow", "glow.yml.tmpl");
  const herdrConfig = join(root, "dot_config", "herdr", "config.toml.tmpl");

  replaceRequired(
    gitConfig,
    /(\[delta\]\n\s*light = )(true|false)/,
    `$1${isDark ? "false" : "true"}`,
  );
  replaceRequired(
    glowConfig,
    /^style:.*$/m,
    isDark ? 'style: "{{ .chezmoi.homeDir }}/.config/glow/gruber-darker.json"' : "style: light",
  );

  replaceRequired(
    herdrConfig,
    /(\[theme\]\nname = ")(gruvbox|gruvbox-light|terminal)(")/,
    `$1${isDark ? "terminal" : "gruvbox-light"}$3`,
  );
}

function applyAppearance(home: string) {
  run("chezmoi", [
    "apply",
    "--force",
    join(home, ".config", "git", "config"),
    join(home, ".config", "glow", "glow.yml"),
    join(home, ".config", "herdr", "config.toml"),
  ]);
}

function main() {
  const home = process.env.HOME;

  if (!home) {
    throw new Error("HOME is not set");
  }

  const isDark = !getMacAppearance();

  updateSourceFiles(isDark);
  applyAppearance(home);
  setMacAppearance(isDark);
  writeFileSync(join(home, ".config", "theme", "appearance.changed"), `${Date.now()}\n`);
  optionalRun("herdr", ["server", "reload-config"]);

  console.log(`Appearance set to ${isDark ? "dark" : "light"}`);
}

main();
