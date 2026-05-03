import { spawn } from "node:child_process"
import path from "node:path"
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent"

const TITLE = "Pi"
const MIN_INTERVAL_MS = 1200

let lastNotificationAt = 0
let lastNotificationKey = ""

function sessionLabel(pi: ExtensionAPI): string {
  const session = pi.getSessionName()
  const cwd = path.basename(process.cwd())
  return session ? `${session} · ${cwd}` : cwd
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'"'"'`)}'`
}

function notify(title: string, subtitle: string, body: string): void {
  const key = `${title}\n${subtitle}\n${body}`
  const now = Date.now()
  if (key === lastNotificationKey && now - lastNotificationAt < MIN_INTERVAL_MS)
    return
  lastNotificationKey = key
  lastNotificationAt = now

  const script = [
    "if command -v cmux >/dev/null 2>&1; then",
    `cmux notify --title ${shellQuote(title)} --subtitle ${shellQuote(subtitle)} --body ${shellQuote(body)}`,
    "else",
    `osascript -e ${shellQuote(`display notification ${JSON.stringify(body)} with title ${JSON.stringify(title)}`)}`,
    "fi",
  ].join(" ")

  const child = spawn("sh", ["-lc", script], {
    detached: true,
    stdio: "ignore",
  })
  child.unref()
}

function summarizeToolInput(input: unknown): string {
  if (!input || typeof input !== "object") return ""
  const data = input as Record<string, unknown>
  const prompt = data["prompt"]
  const title = data["title"]
  const description = data["description"]
  const command = data["command"]
  const text =
    typeof prompt === "string"
      ? prompt
      : typeof title === "string"
        ? title
        : typeof description === "string"
          ? description
          : typeof command === "string"
            ? command
            : ""
  return text.replace(/\s+/g, " ").trim().slice(0, 160)
}

export default function (pi: ExtensionAPI): void {
  pi.on("agent_end", async () => {
    notify(TITLE, "Done", `Ready for input · ${sessionLabel(pi)}`)
  })

  pi.on("tool_call", async (event) => {
    if (["ask_user", "input", "confirm", "select"].includes(event.toolName)) {
      const summary = summarizeToolInput(event.input)
      notify(
        TITLE,
        "Action needed",
        summary || `Waiting for your input · ${sessionLabel(pi)}`,
      )
    }
  })

  pi.on("tool_execution_end", async (event) => {
    if (event.isError) {
      notify(
        TITLE,
        "Tool error",
        `${event.toolName} failed · ${sessionLabel(pi)}`,
      )
      return
    }

    if (["Agent", "agent", "Task"].includes(event.toolName)) {
      notify(
        TITLE,
        "Subagent done",
        `Background task finished · ${sessionLabel(pi)}`,
      )
    }
  })
}
