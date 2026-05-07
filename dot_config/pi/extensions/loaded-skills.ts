import { existsSync, realpathSync } from "node:fs"
import { resolve } from "node:path"
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent"

export const LOADED_SKILL_ENTRY_TYPE = "loaded-skill"

const STATUS_KEY = "loaded-skills"

type SkillCommand = {
  name?: string
  source?: string
  sourceInfo?: {
    path?: string
  }
}

type LoadedSkillEntryData = {
  name?: string
}

function normalizePath(path: string, cwd: string): string {
  const absolutePath = path.startsWith("/") ? path : resolve(cwd, path)
  try {
    if (existsSync(absolutePath)) return realpathSync.native(absolutePath)
  } catch {
    // Fall back to the resolved path below.
  }
  return absolutePath
}

function getCurrentSkillPathMap(
  pi: ExtensionAPI,
  cwd: string,
): Map<string, string> {
  const skills = new Map<string, string>()

  for (const command of pi.getCommands() as SkillCommand[]) {
    if (command.source !== "skill") continue
    if (!command.name?.startsWith("skill:")) continue
    if (!command.sourceInfo?.path) continue

    skills.set(
      normalizePath(command.sourceInfo.path, cwd),
      command.name.slice("skill:".length),
    )
  }

  return skills
}

function updateStatus(ctx: ExtensionContext, loadedSkills: Set<string>): void {
  if (loadedSkills.size === 0) {
    ctx.ui.setStatus(STATUS_KEY, undefined)
    return
  }

  const status = `loaded: ${[...loadedSkills].join(", ")}`
  ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("dim", status))
}

function restoreLoadedSkills(ctx: ExtensionContext): Set<string> {
  const loadedSkills = new Set<string>()

  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type !== "custom") continue
    if (entry.customType !== LOADED_SKILL_ENTRY_TYPE) continue

    const data = entry.data as LoadedSkillEntryData | undefined
    if (typeof data?.name === "string" && data.name.trim()) {
      loadedSkills.add(data.name)
    }
  }

  return loadedSkills
}

export default function (pi: ExtensionAPI): void {
  let loadedSkills = new Set<string>()

  function refreshLoadedSkills(ctx: ExtensionContext): void {
    loadedSkills = restoreLoadedSkills(ctx)
    updateStatus(ctx, loadedSkills)
  }

  pi.on("session_start", async (_event, ctx) => {
    refreshLoadedSkills(ctx)
  })

  pi.on("session_tree", async (_event, ctx) => {
    refreshLoadedSkills(ctx)
  })

  pi.on("tool_result", async (event, ctx) => {
    if (event.toolName !== "read" || event.isError) return

    const input = event.input as { path?: unknown }
    if (typeof input.path !== "string") return

    const readPath = normalizePath(input.path, ctx.cwd)
    const skillName = getCurrentSkillPathMap(pi, ctx.cwd).get(readPath)
    if (!skillName || loadedSkills.has(skillName)) return

    loadedSkills.add(skillName)
    pi.appendEntry(LOADED_SKILL_ENTRY_TYPE, { name: skillName })
    updateStatus(ctx, loadedSkills)
  })
}
