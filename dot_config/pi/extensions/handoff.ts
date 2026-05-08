import type { AgentMessage } from "@earendil-works/pi-agent-core"
import { complete, type Message } from "@earendil-works/pi-ai"
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  SessionEntry,
} from "@earendil-works/pi-coding-agent"
import {
  BorderedLoader,
  convertToLlm,
  serializeConversation,
} from "@earendil-works/pi-coding-agent"

const HANDOFF_MODEL = {
  provider: "openai-codex",
  modelId: "gpt-5.4-mini",
} as const

type NewSessionOptions = NonNullable<
  Parameters<ExtensionCommandContext["newSession"]>[0]
>
type HandoffSessionContext = Parameters<
  NonNullable<NewSessionOptions["withSession"]>
>[0]

type HandoffAutosendState = {
  interval: ReturnType<typeof setInterval>
  timeout: ReturnType<typeof setTimeout>
  unsubscribeInput: () => void
}

const CONTEXT_SUMMARY_SYSTEM_PROMPT = `You are a context transfer assistant. Given a coding conversation and the user's goal for a new session, generate only concise markdown bullets from the current assistant's perspective that summarize relevant context for continuing the work.

Include:
- Concrete decisions made
- Files discussed or modified
- Commands, checks, errors, or blockers that matter
- Important constraints or user preferences

Write in first person for work the assistant did.
Use active phrasing such as "I edited", "I checked", and "I found".
Avoid passive phrasing such as "was edited", "were checked", or "was found".
Use "the user" for prior-session user-only instructions, preferences, or constraints.
Use "we agreed" only for decisions jointly reached with the user.
Prefer "- I edited \`file.ts\` to ..." over "- \`file.ts\` was edited to ...".
Use 8-14 bullets unless the conversation is very short.
Use a flat bullet list only.
Do not use nested bullets.
If listing multiple related items, keep them inline in one bullet.
Mention commands or checks only when their result matters for continuing the work.
Summarize command/check outcomes instead of listing every command.
Do not include headings.
Do not include a task section.
Do not rewrite, quote, or summarize the user's goal.
Do not include preamble or closing text.
Every line must be a markdown bullet starting with "- ".`

const HANDOFF_AUTOSEND_MS = 10_000
const HANDOFF_STATUS_KEY = "handoff-autosend"
const HANDOFF_SESSION_TAG = "[handoff]"
const LOADED_SKILL_ENTRY_TYPE = "loaded-skill"

type LoadedSkillEntryData = {
  name?: string
}

function buildHandoffSessionName(goal: string): string {
  return `${HANDOFF_SESSION_TAG} ${goal.replace(/\s+/g, " ").trim()}`
}

function buildHandoffPrompt(
  goal: string,
  summary: string,
  parentSession: string | null,
  loadedSkills: string[],
): string {
  const intro = parentSession
    ? `Continuing work from session ${parentSession}. If you need details not included here, use session_query.`
    : "Continuing work in a new session. If you need details not included here, use session_query."

  const skillInstruction =
    loadedSkills.length > 0
      ? `Load these skills again before continuing: ${loadedSkills.join(", ")}.`
      : ""

  return [intro, summary.trim(), skillInstruction, goal]
    .filter((part) => part.length > 0)
    .join("\n\n")
}

function getLoadedSkills(entries: SessionEntry[]): string[] {
  const skills = new Set<string>()

  for (const entry of entries) {
    if (entry.type !== "custom") continue
    if (entry.customType !== LOADED_SKILL_ENTRY_TYPE) continue

    const data = entry.data as LoadedSkillEntryData | undefined
    if (typeof data?.name === "string" && data.name.trim()) {
      skills.add(data.name)
    }
  }

  return [...skills]
}

function clearHandoffAutosend(
  ctx: ExtensionContext,
  state: HandoffAutosendState,
): void {
  clearInterval(state.interval)
  clearTimeout(state.timeout)
  state.unsubscribeInput()
  ctx.ui.setStatus(HANDOFF_STATUS_KEY, undefined)
}

function scheduleHandoffAutosend(
  ctx: HandoffSessionContext,
  prompt: string,
): void {
  ctx.ui.setEditorText(prompt)

  let state: HandoffAutosendState | null = null
  let remainingSeconds = Math.ceil(HANDOFF_AUTOSEND_MS / 1000)
  const setStatus = () => {
    ctx.ui.setStatus(
      HANDOFF_STATUS_KEY,
      `handoff autosends in ${remainingSeconds}s; edit or move cursor to cancel`,
    )
  }
  const cancel = () => {
    if (!state) return
    clearHandoffAutosend(ctx, state)
    state = null
  }

  const unsubscribeInput = ctx.ui.onTerminalInput(() => {
    cancel()
    return undefined
  })
  const interval = setInterval(() => {
    remainingSeconds -= 1
    if (remainingSeconds > 0) {
      setStatus()
    }
  }, 1000)
  const timeout = setTimeout(() => {
    if (!state) return
    clearHandoffAutosend(ctx, state)
    state = null

    if (ctx.ui.getEditorText() !== prompt) return
    ctx.ui.setEditorText("")
    void ctx.sendUserMessage(prompt)
  }, HANDOFF_AUTOSEND_MS)

  state = { interval, timeout, unsubscribeInput }
  setStatus()
}

async function generateContextSummary(
  ctx: ExtensionContext,
  messages: AgentMessage[],
  goal: string,
  signal?: AbortSignal,
): Promise<string | null> {
  const model = ctx.modelRegistry.find(
    HANDOFF_MODEL.provider,
    HANDOFF_MODEL.modelId,
  )
  if (!model) {
    throw new Error(
      `Handoff model not found: ${HANDOFF_MODEL.provider}/${HANDOFF_MODEL.modelId}`,
    )
  }

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model)
  if (!auth.ok) {
    throw new Error(auth.error)
  }

  const conversationText = serializeConversation(convertToLlm(messages))
  const userMessage: Message = {
    role: "user",
    content: [
      {
        type: "text",
        text: `## Conversation History\n\n${conversationText}\n\n## Goal For New Session\n\n${goal}`,
      },
    ],
    timestamp: Date.now(),
  }

  const response = await complete(
    model,
    { systemPrompt: CONTEXT_SUMMARY_SYSTEM_PROMPT, messages: [userMessage] },
    {
      ...(auth.apiKey ? { apiKey: auth.apiKey } : {}),
      ...(auth.headers ? { headers: auth.headers } : {}),
      ...(signal ? { signal } : {}),
    },
  )

  if (response.stopReason === "aborted") return null

  return response.content
    .filter((c): c is { type: "text"; text: string } => c.type === "text")
    .map((c) => c.text)
    .join("\n")
    .trim()
}

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("handoff", {
    description: "Create a new session with an AI-generated handoff summary",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("Handoff requires interactive mode.", "error")
        return
      }

      const goal =
        args.trim() || (await ctx.ui.editor("Goal for new session"))?.trim()
      if (!goal) {
        ctx.ui.notify("Handoff cancelled.", "warning")
        return
      }

      const handoffModel = ctx.modelRegistry.find(
        HANDOFF_MODEL.provider,
        HANDOFF_MODEL.modelId,
      )
      if (!handoffModel) {
        ctx.ui.notify(
          `Handoff model not found: ${HANDOFF_MODEL.provider}/${HANDOFF_MODEL.modelId}`,
          "error",
        )
        return
      }

      const auth = await ctx.modelRegistry.getApiKeyAndHeaders(handoffModel)
      if (!auth.ok) {
        ctx.ui.notify(`Handoff model unavailable: ${auth.error}`, "error")
        return
      }

      const branch = ctx.sessionManager.getBranch()
      const messages = branch
        .filter(
          (entry): entry is SessionEntry & { type: "message" } =>
            entry.type === "message",
        )
        .map((entry) => entry.message)

      if (messages.length === 0) {
        ctx.ui.notify("No conversation to hand off.", "error")
        return
      }

      const currentSessionFile = ctx.sessionManager.getSessionFile()
      const summary = await ctx.ui.custom<string | null>(
        (tui, theme, _kb, done) => {
          const loader = new BorderedLoader(
            tui,
            theme,
            `Generating handoff with ${HANDOFF_MODEL.provider}/${HANDOFF_MODEL.modelId}...`,
          )
          loader.onAbort = () => done(null)

          generateContextSummary(ctx, messages, goal, loader.signal)
            .then(done)
            .catch((err) => {
              console.error("Handoff generation failed:", err)
              done(
                `__ERROR__${err instanceof Error ? err.message : String(err)}`,
              )
            })

          return loader
        },
      )

      if (summary === null) {
        ctx.ui.notify("Handoff cancelled.", "warning")
        return
      }
      if (summary.startsWith("__ERROR__")) {
        ctx.ui.notify(summary.slice("__ERROR__".length), "error")
        return
      }

      const finalPrompt = buildHandoffPrompt(
        goal,
        summary,
        currentSessionFile ?? null,
        getLoadedSkills(branch),
      )

      await (ctx as ExtensionCommandContext).newSession({
        ...(currentSessionFile ? { parentSession: currentSessionFile } : {}),
        setup: async (sessionManager) => {
          sessionManager.appendSessionInfo(buildHandoffSessionName(goal))
        },
        withSession: async (newCtx) => {
          scheduleHandoffAutosend(newCtx, finalPrompt)
        },
      })
    },
  })
}
