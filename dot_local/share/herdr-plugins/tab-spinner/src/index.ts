import { mkdir, rm } from "node:fs/promises"
import { fileURLToPath } from "node:url"

import { currentTabLabel, renameTab } from "./herdr.ts"
import {
  isDecoration,
  processIsAlive,
  readState,
  runtimeDirectory,
  statePathForTab,
  stopWorker,
  writeState,
} from "./state.ts"
import { runWorker, startWorker } from "./worker.ts"

type HerdrStatusEvent = {
  data?: {
    agent?: unknown
    agent_status?: unknown
  }
}

const scriptPath = fileURLToPath(import.meta.url)

async function updateFromEvent(event: HerdrStatusEvent): Promise<void> {
  const data = event.data
  const tabId = process.env.HERDR_TAB_ID
  const status = data?.agent_status

  if (typeof data?.agent !== "string") return
  if (!tabId || typeof status !== "string") return

  const statePath = statePathForTab(tabId)
  const currentLabel = await currentTabLabel(tabId)
  const state =
    (await readState(statePath)) ||
    (currentLabel
      ? {
          tabId,
          baseLabel: currentLabel,
          decoratedLabel: "",
        }
      : undefined)
  if (!state) return
  state.tabId = tabId

  if (currentLabel && !isDecoration(currentLabel, state)) {
    state.baseLabel = currentLabel
  }

  state.mode =
    status === "working" ? "working" : status === "blocked" ? "blocked" : "idle"

  if (state.mode === "idle") {
    const workerPid = state.workerPid
    state.workerPid = undefined
    await writeState(statePath, state)
    stopWorker(workerPid)

    const latestLabel = await currentTabLabel(tabId)
    if (state.baseLabel && latestLabel && isDecoration(latestLabel, state)) {
      await renameTab(tabId, state.baseLabel)
    }
    await rm(statePath, { force: true })
    return
  }

  if (state.mode === "blocked") {
    stopWorker(state.workerPid)
    state.workerPid = undefined
    state.decoratedLabel = `⏸ ${state.baseLabel}`
    await writeState(statePath, state)
    await renameTab(tabId, state.decoratedLabel)
    return
  }

  state.workerPid = processIsAlive(state.workerPid)
    ? state.workerPid
    : undefined
  await mkdir(runtimeDirectory, { recursive: true })
  await writeState(statePath, state)

  if (!state.workerPid) {
    state.workerPid = startWorker(scriptPath, statePath, tabId)
    await writeState(statePath, state)
  }
}

async function main(): Promise<void> {
  if (process.argv[2] === "--worker") {
    const statePath = process.argv[3]
    const tabId = process.argv[4]
    if (!statePath || !tabId) return
    await runWorker(statePath, tabId)
    return
  }

  const rawEvent = process.env.HERDR_PLUGIN_EVENT_JSON
  if (!rawEvent) return

  try {
    await updateFromEvent(JSON.parse(rawEvent) as HerdrStatusEvent)
  } catch {
    // Ignore malformed or incomplete event payloads.
  }
}

await main()
