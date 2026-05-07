import { readFileSync } from "node:fs"
import path from "node:path"
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent"

type ThinkingLevel = Parameters<ExtensionAPI["setThinkingLevel"]>[0]

type PreferredThinkingSettings = {
  preferredThinking?: Record<string, unknown>
}

const SETTINGS_PATH = path.join(getAgentDir(), "settings.json")
const VALID_THINKING_LEVELS = new Set<ThinkingLevel>([
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
])

function getModelKey(provider: string, modelId: string): string {
  return `${provider}/${modelId}`
}

function readPreferredThinking(): Readonly<Record<string, ThinkingLevel>> {
  try {
    const content = readFileSync(SETTINGS_PATH, "utf-8")
    const settings = JSON.parse(content) as PreferredThinkingSettings
    const configured = settings.preferredThinking
    if (!configured || typeof configured !== "object") return {}

    const preferredThinking: Record<string, ThinkingLevel> = {}
    for (const [modelKey, level] of Object.entries(configured)) {
      if (
        typeof level === "string" &&
        VALID_THINKING_LEVELS.has(level as ThinkingLevel)
      ) {
        preferredThinking[modelKey] = level as ThinkingLevel
      }
    }

    return preferredThinking
  } catch {
    return {}
  }
}

function applyPreferredThinking(
  pi: ExtensionAPI,
  provider: string,
  modelId: string,
): void {
  const modelKey = getModelKey(provider, modelId)
  const preferredThinking = readPreferredThinking()[modelKey]
  if (!preferredThinking) return

  if (pi.getThinkingLevel() !== preferredThinking) {
    pi.setThinkingLevel(preferredThinking)
  }
}

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.model) return
    applyPreferredThinking(pi, ctx.model.provider, ctx.model.id)
  })

  pi.on("model_select", async (event) => {
    applyPreferredThinking(pi, event.model.provider, event.model.id)
  })
}
