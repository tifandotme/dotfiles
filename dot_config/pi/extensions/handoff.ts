import type { AgentMessage } from "@mariozechner/pi-agent-core"
import { complete, type Message } from "@mariozechner/pi-ai"
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  SessionEntry,
} from "@mariozechner/pi-coding-agent"
import {
  BorderedLoader,
  convertToLlm,
  serializeConversation,
} from "@mariozechner/pi-coding-agent"

const HANDOFF_MODEL = {
  provider: "openai-codex",
  modelId: "gpt-5.4-mini",
} as const

const HANDOFF_GLOBAL_KEY = Symbol.for("local-handoff-pending")

type PendingHandoff = {
  prompt: string
}

type HandoffAutosendState = {
  interval: ReturnType<typeof setInterval>
  timeout: ReturnType<typeof setTimeout>
  unsubscribeInput: () => void
}

function getPendingHandoff(): PendingHandoff | null {
  return (
    ((globalThis as Record<PropertyKey, unknown>)[HANDOFF_GLOBAL_KEY] as
      | PendingHandoff
      | null
      | undefined) ?? null
  )
}

function setPendingHandoff(data: PendingHandoff | null): void {
  if (data) {
    ;(globalThis as Record<PropertyKey, unknown>)[HANDOFF_GLOBAL_KEY] = data
  } else {
    delete (globalThis as Record<PropertyKey, unknown>)[HANDOFF_GLOBAL_KEY]
  }
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

function buildHandoffPrompt(
  goal: string,
  summary: string,
  parentSession: string | null,
): string {
  const intro = parentSession
    ? `Continuing work from session ${parentSession}. If you need details not included here, use session_query.`
    : "Continuing work in a new session. If you need details not included here, use session_query."

  return `${intro}\n\n${summary.trim()}\n\n${goal}`
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
  pi: ExtensionAPI,
  ctx: ExtensionContext,
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
    pi.sendUserMessage(prompt)
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
  pi.on("session_start", async (event, ctx) => {
    if (event.reason !== "new") return
    const pending = getPendingHandoff()
    if (!pending) return
    setPendingHandoff(null)
    scheduleHandoffAutosend(pi, ctx, pending.prompt)
  })

  pi.registerCommand("handoff", {
    description: "Create a new session with an AI-generated handoff summary",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("Handoff requires interactive mode.", "error")
        return
      }

      const goal = args.trim()
      if (!goal) {
        ctx.ui.notify("Usage: /handoff <goal>", "error")
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
      )

      setPendingHandoff({ prompt: finalPrompt })
      const result = await (ctx as ExtensionCommandContext).newSession(
        currentSessionFile ? { parentSession: currentSessionFile } : undefined,
      )
      if (result.cancelled) {
        setPendingHandoff(null)
      }
    },
  })
}
