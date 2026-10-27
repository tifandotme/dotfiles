import { readFile, rename, writeFile } from "node:fs/promises"
import os from "node:os"
import path from "node:path"

export const FRAMES = ["◐", "◓", "◑", "◒"]
export const INTERVAL_MS = 120
export const runtimeDirectory = path.join(
  process.env.XDG_RUNTIME_DIR || os.tmpdir(),
  "herdr-tab-spinner",
)

export type SpinnerMode = "working" | "blocked" | "idle"

export type SpinnerState = {
  tabId: string
  baseLabel: string
  decoratedLabel: string
  mode?: SpinnerMode
  workerPid?: number
}

export function statePathForTab(tabId: string): string {
  return path.join(runtimeDirectory, `${encodeURIComponent(tabId)}.json`)
}

export async function readState(
  statePath: string,
): Promise<SpinnerState | undefined> {
  try {
    return JSON.parse(await readFile(statePath, "utf8")) as SpinnerState
  } catch {
    return undefined
  }
}

export async function writeState(
  statePath: string,
  state: SpinnerState,
): Promise<void> {
  const temporaryPath = `${statePath}.${process.pid}.tmp`
  await writeFile(temporaryPath, JSON.stringify(state))
  await rename(temporaryPath, statePath)
}

export function processIsAlive(pid: number | undefined): boolean {
  if (pid === undefined || !Number.isInteger(pid)) return false
  try {
    process.kill(pid, 0)
    return true
  } catch {
    return false
  }
}

export function stopWorker(pid: number | undefined): void {
  if (pid === undefined || !Number.isInteger(pid)) return
  try {
    process.kill(pid)
  } catch {
    // The worker may have stopped already.
  }
}

export function isDecoration(label: string, state: SpinnerState): boolean {
  return (
    label === state.decoratedLabel ||
    FRAMES.some((frame) => label === `${frame} ${state.baseLabel}`) ||
    label === `⏸ ${state.baseLabel}`
  )
}

const MAX_LABEL_LENGTH = 24

// Herdr auto-labels a tab with the last shell command ("> cmd ..."). Renaming
// pins that label, so cap it before it is pinned.
export function undecorate(label: string): string {
  const base = label
    .replace(new RegExp(`^(?:[${FRAMES.join("")}⏸] )+`), "")
    .replace(/^> /, "")
  return base.length > MAX_LABEL_LENGTH
    ? `${base.slice(0, MAX_LABEL_LENGTH - 1)}…`
    : base
}
