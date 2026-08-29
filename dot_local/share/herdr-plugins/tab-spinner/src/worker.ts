import { spawn } from "node:child_process"
import { currentTabLabel, renameTab } from "./herdr.ts"
import {
  FRAMES,
  INTERVAL_MS,
  isDecoration,
  readState,
  writeState,
} from "./state.ts"

export function startWorker(
  scriptPath: string,
  statePath: string,
  tabId: string,
): number | undefined {
  const worker = spawn(
    process.execPath,
    [scriptPath, "--worker", statePath, tabId],
    {
      detached: true,
      stdio: "ignore",
    },
  )
  worker.unref()
  return worker.pid
}

export async function runWorker(
  statePath: string,
  tabId: string,
): Promise<void> {
  let frameIndex = 0

  while (true) {
    const state = await readState(statePath)
    if (!state || state.mode !== "working" || state.tabId !== tabId) return

    const currentLabel = await currentTabLabel(tabId)
    if (!currentLabel) return

    const baseLabel = isDecoration(currentLabel, state)
      ? state.baseLabel
      : currentLabel
    if (!baseLabel) return

    const decoratedLabel = `${FRAMES[frameIndex]} ${baseLabel}`
    await renameTab(tabId, decoratedLabel)

    const latest = await readState(statePath)
    if (!latest || latest.mode !== "working") return
    latest.baseLabel = baseLabel
    latest.decoratedLabel = decoratedLabel
    await writeState(statePath, latest)

    frameIndex = (frameIndex + 1) % FRAMES.length
    await new Promise((resolve) => setTimeout(resolve, INTERVAL_MS))
  }
}
