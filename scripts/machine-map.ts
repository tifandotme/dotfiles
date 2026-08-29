#!/usr/bin/env bun
/** Compare rendered chezmoi state for the main Mac and the box VPS. */

import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { basename, join } from "node:path";

const machines = [
  { os: "darwin", hostname: "main" },
  { os: "linux", hostname: "box" },
] as const;
type Machine = (typeof machines)[number];

function overrideData(machine: Machine) {
  return JSON.stringify({ chezmoi: { os: machine.os, hostname: machine.hostname } });
}

function runDelta(args: string[], directory: string) {
  const width = process.stdout.columns;
  const result = spawnSync("delta", width ? [`--width=${width}`, ...args] : args, {
    cwd: directory,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && result.status !== 1) {
    throw new Error(`delta exited with ${result.status}`);
  }
}

function managed(machine: Machine) {
  return execFileSync("chezmoi", ["--override-data", overrideData(machine), "managed", "--include", "files"])
    .toString()
    .trim()
    .split("\n")
    .filter(Boolean);
}

function render(machine: Machine, target: string) {
  return execFileSync("chezmoi", ["--override-data", overrideData(machine), "cat", join(homedir(), target)]);
}

function withTempDir(run: (directory: string) => void) {
  const directory = mkdtempSync(join(tmpdir(), "machine-map-"));
  try {
    run(directory);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

function showInventory(mainFiles: string[], boxFiles: string[]) {
  const mainSet = new Set(mainFiles);
  const boxSet = new Set(boxFiles);
  const mainOnly = mainFiles.filter((file) => !boxSet.has(file));
  const boxOnly = boxFiles.filter((file) => !mainSet.has(file));

  if (mainOnly.length === 0 && boxOnly.length === 0) {
    console.log("No machine-specific files.");
    return;
  }

  withTempDir((directory) => {
    const mainName = `MAIN ONLY (${mainOnly.length})`;
    const boxName = `BOX ONLY (${boxOnly.length})`;
    writeFileSync(join(directory, mainName), `${mainFiles.join("\n")}\n`);
    writeFileSync(join(directory, boxName), `${boxFiles.join("\n")}\n`);
    runDelta(
      [
        "--paging=never",
        "--side-by-side",
        "--diff-args=-U0",
        "--hunk-header-style=omit",
        "--line-numbers-left-format=",
        "--line-numbers-right-format=",
        "--wrap-max-lines=unlimited",
        mainName,
        boxName,
      ],
      directory,
    );
  });
}

function changedSharedFiles(mainFiles: string[], boxFiles: string[]) {
  const boxSet = new Set(boxFiles);
  const changed: string[] = [];

  for (const target of mainFiles) {
    if (!boxSet.has(target)) continue;
    if (!render(machines[0], target).equals(render(machines[1], target))) changed.push(target);
  }

  return changed;
}

function showFocusedDiff(target: string, mainFiles: string[], boxFiles: string[]) {
  const mainHasTarget = mainFiles.includes(target);
  const boxHasTarget = boxFiles.includes(target);

  if (!mainHasTarget && !boxHasTarget) throw new Error(`Not a managed file: ${target}`);

  const mainContent = mainHasTarget ? render(machines[0], target) : Buffer.alloc(0);
  const boxContent = boxHasTarget ? render(machines[1], target) : Buffer.alloc(0);

  if (mainContent.equals(boxContent)) {
    console.log(`No rendered differences: ${target}`);
    return;
  }

  console.log(`Rendered diff: ${target}\n`);
  withTempDir((directory) => {
    const mainName = `main:${basename(target)}`;
    const boxName = `box:${basename(target)}`;
    writeFileSync(join(directory, mainName), mainContent);
    writeFileSync(join(directory, boxName), boxContent);
    runDelta(["--side-by-side", mainName, boxName], directory);
  });
}

function main() {
  const targets = process.argv.slice(2);
  if (targets.length > 1) throw new Error("Usage: machine-map [exact-managed-path]");

  const mainFiles = managed(machines[0]);
  const boxFiles = managed(machines[1]);
  const target = targets[0];

  if (target) {
    showFocusedDiff(target, mainFiles, boxFiles);
    return;
  }

  showInventory(mainFiles, boxFiles);
  const changed = changedSharedFiles(mainFiles, boxFiles);
  console.log("\nInspect a rendered diff:");
  console.log("  mise run machine-map -- .Brewfile");
  console.log(`\nCHANGED SHARED FILES (${changed.length})`);
  console.log(changed.length === 0 ? "(none)" : changed.join("\n"));
}

try {
  main();
} catch (error: unknown) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}
