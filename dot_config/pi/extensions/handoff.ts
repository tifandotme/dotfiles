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

const CONTEXT_SUMMARY_SYSTEM_PROMPT = `You are a context transfer assistant. Given a coding conversation and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes only the relevant technical context
2. Lists relevant files discussed or modified
3. States the next task clearly
4. Is self-contained and ready to send to another coding agent session

Use this format:

## Context
- ...

## Files
- path/to/file

## Task
...

Be concise and specific. Output only the prompt body.`

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
  pi.on("session_start", async (event) => {
    if (event.reason !== "new") return
    const pending = getPendingHandoff()
    if (!pending) return
    setPendingHandoff(null)
    pi.sendUserMessage(pending.prompt)
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

      const parentBlock = currentSessionFile
        ? `Parent session: ${currentSessionFile}\n\nYou can use the session_query tool to ask that parent session for more detail if needed.\n\n`
        : ""
      const finalPrompt = `${goal}\n\n${parentBlock}${summary}`

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
