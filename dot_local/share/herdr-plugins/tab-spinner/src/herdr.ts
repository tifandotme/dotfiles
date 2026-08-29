import { execFile } from "node:child_process"
import { promisify } from "node:util"

type HerdrResponse = {
  result?: {
    tab?: {
      label?: unknown
    }
  }
}

const execFileAsync = promisify(execFile)

export async function renameTab(tabId: string, label: string): Promise<void> {
  try {
    await execFileAsync("herdr", ["tab", "rename", tabId, label], {
      timeout: 1_000,
      maxBuffer: 8 * 1024,
    })
  } catch {
    // Herdr may have closed the tab already.
  }
}

export async function currentTabLabel(
  tabId: string,
): Promise<string | undefined> {
  try {
    const { stdout } = await execFileAsync("herdr", ["tab", "get", tabId], {
      timeout: 1_000,
      maxBuffer: 64 * 1024,
    })
    const response = JSON.parse(stdout) as HerdrResponse
    const label = response.result?.tab?.label
    return typeof label === "string" ? label : undefined
  } catch {
    return undefined
  }
}
