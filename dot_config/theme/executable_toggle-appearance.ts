#!/usr/bin/env bun

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

type JsonObject = Record<string, unknown>;

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

function homeBin(command: string) {
  const home = process.env.HOME;

  return home ? join(home, ".local", "bin", command) : command;
}

function sourceRoot() {
  return run("chezmoi", ["source-path"], { quiet: true });
}

function readJsonObject(path: string) {
  const parsed: unknown = JSON.parse(readFileSync(path, "utf8"));

  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`Expected JSON object: ${path}`);
  }

  return parsed as JsonObject;
}

function writeJson(path: string, value: JsonObject) {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
}

function replaceRequired(path: string, pattern: RegExp, replacement: string) {
  const current = readFileSync(path, "utf8");
  const next = current.replace(pattern, replacement);

  if (next === current) {
    throw new Error(`No matching content to update in ${path}`);
  }

  writeFileSync(path, next);
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
  const piSettings = join(root, "dot_config", "pi", "private_settings.json");
  const piCodePreviews = join(root, "dot_config", "pi", "private_code-previews.json");
  const claudeSettings = join(root, "dot_config", "claude", "private_settings.json");
  const herdrConfig = join(root, "dot_config", "herdr", "config.toml");

  replaceRequired(gitConfig, /(\[delta\]\n\s*light = )(true|false)/, `$1${isDark ? "false" : "true"}`);
  replaceRequired(
    glowConfig,
    /^style:.*$/m,
    isDark ? 'style: "{{ .chezmoi.homeDir }}/.config/glow/gruber-darker.json"' : "style: light",
  );

  const settings = readJsonObject(piSettings);
  settings.theme = isDark ? "dark" : "light";
  writeJson(piSettings, settings);

  const codePreviews = readJsonObject(piCodePreviews);
  codePreviews.shikiTheme = isDark ? "github-dark-default" : "github-light-default";
  writeJson(piCodePreviews, codePreviews);

  const claude = readJsonObject(claudeSettings);
  claude.theme = isDark ? "dark" : "light";
  writeJson(claudeSettings, claude);

  replaceRequired(herdrConfig, /(\[theme\]\nname = ")(gruvbox|terminal)(")/, `$1${isDark ? "gruvbox" : "terminal"}$3`);
}

function applyAppearance() {
  const home = process.env.HOME;

  if (!home) {
    throw new Error("HOME is not set");
  }

  run("chezmoi", [
    "apply",
    "--force",
    join(home, ".config", "git", "config"),
    join(home, ".config", "glow", "glow.yml"),
    join(home, ".config", "pi", "settings.json"),
    join(home, ".config", "pi", "code-previews.json"),
    join(home, ".config", "claude", "settings.json"),
    join(home, ".config", "herdr", "config.toml"),
  ]);
}

function main() {
  const isDark = !getMacAppearance();

  updateSourceFiles(isDark);
  applyAppearance();
  setMacAppearance(isDark);
  optionalRun(homeBin("herdr"), ["server", "reload-config"]);

  console.log(`Appearance set to ${isDark ? "dark" : "light"}`);
}

main();
