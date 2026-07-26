#!/usr/bin/env bun
/** Compare rendered chezmoi state for the main Mac and the box VPS. */

import { $ } from "bun";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { homedir, tmpdir } from "node:os";
import { basename, join } from "node:path";

interface Machine {
  name: string;
  os: string;
  hostname: string;
}

const machines = [
  { name: "main", os: "darwin", hostname: "main" },
  { name: "box", os: "linux", hostname: "box" },
] as const satisfies readonly Machine[];

function overrideData(machine: Machine) {
  return JSON.stringify({ chezmoi: { os: machine.os, hostname: machine.hostname } });
}

async function managed(machine: Machine) {
  const output =
    await $`chezmoi --override-data ${overrideData(machine)} managed --include files`.text();
  return output.trim().split("\n").filter(Boolean);
}

async function render(machine: Machine, target: string) {
  const result =
    await $`chezmoi --override-data ${overrideData(machine)} cat ${join(homedir(), target)}`
      .quiet()
      .nothrow();

  if (result.exitCode !== 0) {
    throw new Error(
      result.stderr.toString().trim() || `Could not render ${machine.name}:${target}`,
    );
  }

  return result.stdout;
}

async function withTempDir<T>(run: (directory: string) => Promise<T>) {
  const directory = await mkdtemp(join(tmpdir(), "machine-map-"));
  try {
    return await run(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

async function showInventory(mainFiles: string[], boxFiles: string[]) {
  const mainSet = new Set(mainFiles);
  const boxSet = new Set(boxFiles);
  const mainOnly = mainFiles.filter((file) => !boxSet.has(file));
  const boxOnly = boxFiles.filter((file) => !mainSet.has(file));

  if (mainOnly.length === 0 && boxOnly.length === 0) {
    console.log("No machine-specific files.");
    return;
  }

  await withTempDir(async (directory) => {
    const mainName = `MAIN ONLY (${mainOnly.length})`;
    const boxName = `BOX ONLY (${boxOnly.length})`;
    await Promise.all([
      writeFile(join(directory, mainName), `${mainFiles.join("\n")}\n`),
      writeFile(join(directory, boxName), `${boxFiles.join("\n")}\n`),
    ]);

    await $`delta --paging=never --side-by-side --diff-args=-U0 --hunk-header-style=omit --line-numbers-left-format= --line-numbers-right-format= --wrap-max-lines=unlimited ${mainName} ${boxName}`
      .cwd(directory)
      .nothrow();
  });
}

async function changedSharedFiles(mainFiles: string[], boxFiles: string[]) {
  const boxSet = new Set(boxFiles);
  const changed: string[] = [];

  for (const target of mainFiles) {
    if (!boxSet.has(target)) continue;

    const [mainContent, boxContent] = await Promise.all([
      render(machines[0], target),
      render(machines[1], target),
    ]);
    if (!mainContent.equals(boxContent)) changed.push(target);
  }

  return changed;
}

async function showFocusedDiff(target: string, mainFiles: string[], boxFiles: string[]) {
  const mainHasTarget = mainFiles.includes(target);
  const boxHasTarget = boxFiles.includes(target);

  if (!mainHasTarget && !boxHasTarget) {
    throw new Error(`Not a managed file: ${target}`);
  }

  const empty = Buffer.alloc(0);
  const [mainContent, boxContent] = await Promise.all([
    mainHasTarget ? render(machines[0], target) : empty,
    boxHasTarget ? render(machines[1], target) : empty,
  ]);

  if (mainContent.equals(boxContent)) {
    console.log(`No rendered differences: ${target}`);
    return;
  }

  console.log(`Rendered diff: ${target}\n`);
  await withTempDir(async (directory) => {
    const mainName = `main:${basename(target)}`;
    const boxName = `box:${basename(target)}`;
    await Promise.all([
      writeFile(join(directory, mainName), mainContent),
      writeFile(join(directory, boxName), boxContent),
    ]);
    await $`delta --side-by-side ${mainName} ${boxName}`.cwd(directory).nothrow();
  });
}

async function main() {
  if (!Bun.which("delta")) throw new Error("delta was not found on PATH");

  const targets = process.argv.slice(2);
  if (targets.length > 1) {
    throw new Error("Usage: machine-map [exact-managed-path]");
  }

  const [mainFiles, boxFiles] = await Promise.all([managed(machines[0]), managed(machines[1])]);
  const target = targets[0];

  if (target) {
    await showFocusedDiff(target, mainFiles, boxFiles);
    return;
  }

  await showInventory(mainFiles, boxFiles);
  const changed = await changedSharedFiles(mainFiles, boxFiles);
  console.log(`\nCHANGED SHARED FILES (${changed.length})`);
  console.log(changed.length === 0 ? "(none)" : changed.join("\n"));
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
});
