type HerdrResponse = {
  result?: {
    tab?: {
      label?: unknown
    }
  }
}

function runHerdr(args: string[], maxBuffer: number) {
  // Bound both the time and the captured output of a Herdr RPC.
  const timeout = 1_000
  const started = performance.now()
  const result = Bun.spawnSync(["herdr", ...args], {
    stdio: ["ignore", "pipe", "pipe"],
    timeout,
    maxBuffer,
  })
  if (
    !result.success ||
    performance.now() - started >= timeout ||
    result.stdout.length > maxBuffer ||
    result.stderr.length > maxBuffer
  ) return undefined
  return result.stdout
}

export function renameTab(tabId: string, label: string): void {
  try {
    runHerdr(["tab", "rename", tabId, label], 8 * 1024)
  } catch {
    // Herdr may have closed the tab already.
  }
}

export function currentTabLabel(tabId: string): string | undefined {
  try {
    const stdout = runHerdr(["tab", "get", tabId], 64 * 1024)
    if (!stdout) return undefined
    const response = JSON.parse(stdout.toString()) as HerdrResponse
    const label = response.result?.tab?.label
    return typeof label === "string" ? label : undefined
  } catch {
    return undefined
  }
}
