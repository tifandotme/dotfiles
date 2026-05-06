import { spawn } from "node:child_process"
import {
  existsSync,
  readdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs"
import { mkdtemp } from "node:fs/promises"
import os from "node:os"
import path from "node:path"
import { StringEnum, type Message } from "@mariozechner/pi-ai"
import {
  getAgentDir,
  getMarkdownTheme,
  parseFrontmatter,
  type ExtensionAPI,
  type Theme,
} from "@mariozechner/pi-coding-agent"
import { Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui"
import { Type } from "typebox"

const MAX_PARALLEL_TASKS = 6
const MAX_CONCURRENCY = 3
const NAME_PATTERN = /^[a-z][a-z-]*$/
const VALID_THINKING = new Set([
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
])

type AgentConfig = {
  name: string
  description: string
  model?: string
  thinking?: string
  tools?: string[]
  systemPrompt: string
  filePath: string
}

type ThemeLike = Theme

type InvalidAgent = {
  filePath: string
  reason: string
}

type Discovery = {
  dir: string
  agents: AgentConfig[]
  invalid: InvalidAgent[]
}

type TaskInput = {
  agent: string
  task: string
  cwd?: string
}

type SingleResult = {
  agent: string
  task: string
  cwd: string
  exitCode: number
  messages: Message[]
  stderr: string
  output: string
  errorMessage?: string
}

type SubagentDetails = {
  mode: "list" | "single" | "parallel"
  dir: string
  invalid: InvalidAgent[]
  results: SingleResult[]
}

function parseStringField(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim() : undefined
}

function parseTools(value: unknown): string[] | undefined {
  const raw = parseStringField(value)
  if (!raw) return undefined
  const tools = raw
    .split(",")
    .map((tool) => tool.trim())
    .filter(Boolean)
  return tools.length > 0 ? tools : undefined
}

function discoverSubagents(): Discovery {
  const dir = path.join(getAgentDir(), "subagents")
  if (!existsSync(dir)) return { dir, agents: [], invalid: [] }

  const candidates = readdirSync(dir, { withFileTypes: true })
    .filter((entry) => entry.isFile() && entry.name.endsWith(".md"))
    .map((entry) => path.join(dir, entry.name))
    .sort((a, b) => a.localeCompare(b))

  const agents: AgentConfig[] = []
  const invalid: InvalidAgent[] = []
  const seen = new Map<string, string[]>()

  for (const filePath of candidates) {
    try {
      const parsed = parseFrontmatter(readFileSync(filePath, "utf-8"))
      const name = parseStringField(parsed.frontmatter["name"])
      const description = parseStringField(parsed.frontmatter["description"])
      const expectedFileName = name ? `${name}.md` : undefined

      if (!name) {
        invalid.push({
          filePath,
          reason: "missing required frontmatter field: name",
        })
        continue
      }
      if (!NAME_PATTERN.test(name)) {
        invalid.push({ filePath, reason: "name must match /^[a-z][a-z-]*$/" })
        continue
      }
      if (path.basename(filePath) !== expectedFileName) {
        invalid.push({
          filePath,
          reason: `filename must be ${expectedFileName}`,
        })
        continue
      }
      if (!description) {
        invalid.push({
          filePath,
          reason: "missing required frontmatter field: description",
        })
        continue
      }
      if (description.length > 500) {
        invalid.push({
          filePath,
          reason: "description must be 500 characters or less",
        })
        continue
      }
      if (!parsed.body.trim()) {
        invalid.push({ filePath, reason: "system prompt body is empty" })
        continue
      }

      const thinking = parseStringField(parsed.frontmatter["thinking"])
      if (thinking && !VALID_THINKING.has(thinking)) {
        invalid.push({
          filePath,
          reason: `invalid thinking level: ${thinking}`,
        })
        continue
      }

      const agent: AgentConfig = {
        name,
        description,
        systemPrompt: parsed.body.trim(),
        filePath,
      }
      const model = parseStringField(parsed.frontmatter["model"])
      const tools = parseTools(parsed.frontmatter["tools"])
      if (model) agent.model = model
      if (thinking) agent.thinking = thinking
      if (tools) agent.tools = tools
      agents.push(agent)
      seen.set(name, [...(seen.get(name) ?? []), filePath])
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      invalid.push({ filePath, reason: `failed to parse: ${message}` })
    }
  }

  const duplicateNames = new Set(
    Array.from(seen.entries())
      .filter(([, files]) => files.length > 1)
      .map(([name]) => name),
  )
  if (duplicateNames.size === 0) return { dir, agents, invalid }

  return {
    dir,
    agents: agents.filter((agent) => !duplicateNames.has(agent.name)),
    invalid: [
      ...invalid,
      ...Array.from(duplicateNames).flatMap((name) =>
        (seen.get(name) ?? []).map((filePath) => ({
          filePath,
          reason: `duplicate agent name: ${name}`,
        })),
      ),
    ],
  }
}

function formatAgentList(discovery: Discovery): string {
  const lines = [`Available subagents from ${discovery.dir}:`, ""]
  if (discovery.agents.length === 0) {
    lines.push("None.")
  } else {
    for (const agent of discovery.agents) {
      lines.push(`- ${agent.name}: ${agent.description}`)
      if (agent.model) lines.push(`  model: ${agent.model}`)
      if (agent.thinking) lines.push(`  thinking: ${agent.thinking}`)
      if (agent.tools?.length) lines.push(`  tools: ${agent.tools.join(",")}`)
      lines.push(`  path: ${agent.filePath}`)
    }
  }

  if (discovery.invalid.length > 0) {
    lines.push("", "Invalid subagent files:")
    for (const item of discovery.invalid)
      lines.push(`- ${item.filePath}: ${item.reason}`)
  }

  return lines.join("\n")
}

function finalAssistantOutput(messages: Message[]): string {
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i]
    if (!message || message.role !== "assistant") continue
    const content = message.content
    if (typeof content === "string") return content
    for (const part of content) {
      if (typeof part !== "string" && part.type === "text") return part.text
    }
  }
  return ""
}

async function writePromptFile(
  agentName: string,
  systemPrompt: string,
): Promise<{ dir: string; filePath: string }> {
  const dir = await mkdtemp(path.join(os.tmpdir(), "pi-subagent-"))
  const filePath = path.join(dir, `${agentName}.md`)
  writeFileSync(filePath, systemPrompt, { encoding: "utf-8", mode: 0o600 })
  return { dir, filePath }
}

function piInvocation(args: string[]): { command: string; args: string[] } {
  const currentScript = process.argv[1]
  if (
    currentScript &&
    !currentScript.startsWith("/$bunfs/root/") &&
    existsSync(currentScript)
  ) {
    return { command: process.execPath, args: [currentScript, ...args] }
  }
  return { command: "pi", args }
}

async function runSingleAgent(
  defaultCwd: string,
  agent: AgentConfig,
  task: string,
  cwd: string | undefined,
  signal: AbortSignal | undefined,
  onUpdate: ((result: SingleResult) => void) | undefined,
): Promise<SingleResult> {
  const runCwd = cwd ?? defaultCwd
  const args = ["--mode", "json", "-p", "--no-session"]
  if (agent.model) args.push("--model", agent.model)
  if (agent.thinking) args.push("--thinking", agent.thinking)
  if (agent.tools?.length) args.push("--tools", agent.tools.join(","))

  let tempDir: string | undefined
  const result: SingleResult = {
    agent: agent.name,
    task,
    cwd: runCwd,
    exitCode: 0,
    messages: [],
    stderr: "",
    output: "",
  }

  try {
    const temp = await writePromptFile(agent.name, agent.systemPrompt)
    tempDir = temp.dir
    args.push("--append-system-prompt", temp.filePath, `Task: ${task}`)

    let wasAborted = false
    const exitCode = await new Promise<number>((resolve) => {
      const invocation = piInvocation(args)
      const proc = spawn(invocation.command, invocation.args, {
        cwd: runCwd,
        shell: false,
        stdio: ["ignore", "pipe", "pipe"],
      })
      let buffer = ""

      const processLine = (line: string): void => {
        if (!line.trim()) return
        let event: unknown
        try {
          event = JSON.parse(line)
        } catch {
          return
        }
        if (!event || typeof event !== "object") return
        const typedEvent = event as { type?: string; message?: Message }
        if (
          (typedEvent.type === "message_end" ||
            typedEvent.type === "tool_result_end") &&
          typedEvent.message
        ) {
          result.messages.push(typedEvent.message)
          result.output = finalAssistantOutput(result.messages)
          onUpdate?.({ ...result, messages: [...result.messages] })
        }
      }

      proc.stdout.on("data", (data: Buffer) => {
        buffer += data.toString()
        const lines = buffer.split("\n")
        buffer = lines.pop() ?? ""
        for (const line of lines) processLine(line)
      })
      proc.stderr.on("data", (data: Buffer) => {
        result.stderr += data.toString()
      })
      proc.on("close", (code) => {
        if (buffer.trim()) processLine(buffer)
        resolve(code ?? 0)
      })
      proc.on("error", (error) => {
        result.errorMessage = error.message
        resolve(1)
      })

      const kill = (): void => {
        wasAborted = true
        proc.kill("SIGTERM")
        setTimeout(() => {
          if (!proc.killed) proc.kill("SIGKILL")
        }, 5000)
      }
      if (signal?.aborted) kill()
      else signal?.addEventListener("abort", kill, { once: true })
    })

    result.exitCode = exitCode
    if (wasAborted) result.errorMessage = "Subagent was aborted"
    if (!result.output) result.output = finalAssistantOutput(result.messages)
    return result
  } finally {
    if (tempDir) rmSync(tempDir, { recursive: true, force: true })
  }
}

async function mapWithConcurrency<T, R>(
  items: T[],
  concurrency: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results = new Array<R>(items.length)
  let nextIndex = 0
  const workers = new Array(Math.min(concurrency, items.length))
    .fill(undefined)
    .map(async () => {
      while (true) {
        const index = nextIndex++
        if (index >= items.length) return
        results[index] = await fn(items[index] as T, index)
      }
    })
  await Promise.all(workers)
  return results
}

function preview(text: string): string {
  const cleaned = text.trim().replace(/\s+/g, " ")
  if (!cleaned) return "(no output yet)"
  return cleaned.length > 160 ? `${cleaned.slice(0, 160)}...` : cleaned
}

function renderSingle(
  result: SingleResult,
  expanded: boolean,
  theme: ThemeLike,
): Text | Container {
  const failed = result.exitCode !== 0 || Boolean(result.errorMessage)
  const icon = failed ? theme.fg("error", "✗") : theme.fg("success", "✓")
  if (!expanded) {
    return new Text(
      `${icon} ${theme.fg("toolTitle", theme.bold(result.agent))}\n${theme.fg(failed ? "error" : "toolOutput", preview(result.errorMessage ?? result.output ?? result.stderr))}`,
      0,
      0,
    )
  }

  const container = new Container()
  container.addChild(
    new Text(
      `${icon} ${theme.fg("toolTitle", theme.bold(result.agent))}`,
      0,
      0,
    ),
  )
  container.addChild(new Spacer(1))
  container.addChild(new Text(theme.fg("muted", "Task:"), 0, 0))
  container.addChild(new Text(theme.fg("dim", result.task), 0, 0))
  container.addChild(new Spacer(1))
  container.addChild(new Text(theme.fg("muted", "Output:"), 0, 0))
  container.addChild(
    new Markdown(
      (result.output || result.errorMessage || "(no output)").trim(),
      0,
      0,
      getMarkdownTheme(),
    ),
  )
  if (result.stderr.trim()) {
    container.addChild(new Spacer(1))
    container.addChild(new Text(theme.fg("muted", "stderr:"), 0, 0))
    container.addChild(new Text(theme.fg("dim", result.stderr.trim()), 0, 0))
  }
  return container
}

const TaskSchema = Type.Object({
  agent: Type.String({
    description: "Subagent name from ~/.config/pi/subagents/*.md",
  }),
  task: Type.String({ description: "Task to delegate" }),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for this subagent" }),
  ),
})

const SubagentParams = Type.Object({
  action: Type.Optional(StringEnum(["list"] as const)),
  agent: Type.Optional(
    Type.String({ description: "Subagent name for single mode" }),
  ),
  task: Type.Optional(Type.String({ description: "Task for single mode" })),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for single mode" }),
  ),
  tasks: Type.Optional(
    Type.Array(TaskSchema, { description: "Parallel subagent tasks" }),
  ),
  concurrency: Type.Optional(
    Type.Number({
      description: `Parallel concurrency, clamped to 1-${MAX_CONCURRENCY}`,
    }),
  ),
})

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("subagents", {
    description: "List local subagents from ~/.config/pi/subagents",
    handler: async (_args, ctx) => {
      const discovery = discoverSubagents()
      if (ctx.hasUI)
        ctx.ui.notify(
          formatAgentList(discovery),
          discovery.invalid.length > 0 ? "warning" : "info",
        )
    },
  })

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Delegate to local subagents loaded only from the Pi config subagents directory. Supports action=list, single mode, and parallel tasks.",
    promptSnippet:
      "Delegate focused work to local subagents from ~/.config/pi/subagents.",
    promptGuidelines: [
      'Use subagent with agent: "scout" before non-trivial work in unfamiliar code areas when project instructions request it.',
      'Use subagent with agent: "reviewer" only when the user explicitly asks for review.',
    ],
    parameters: SubagentParams,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const discovery = discoverSubagents()
      const makeDetails = (
        mode: SubagentDetails["mode"],
        results: SingleResult[],
      ): SubagentDetails => ({
        mode,
        dir: discovery.dir,
        invalid: discovery.invalid,
        results,
      })

      if (params.action === "list") {
        return {
          content: [
            { type: "text" as const, text: formatAgentList(discovery) },
          ],
          details: makeDetails("list", []),
        }
      }

      const agentByName = new Map(
        discovery.agents.map((agent) => [agent.name, agent]),
      )
      const hasSingle = Boolean(params.agent && params.task)
      const hasParallel = Boolean(params.tasks?.length)
      if (Number(hasSingle) + Number(hasParallel) !== 1) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Provide exactly one mode: action=list, agent+task, or tasks.\n\n${formatAgentList(discovery)}`,
            },
          ],
          details: makeDetails("single", []),
        }
      }

      if (hasSingle && params.agent && params.task) {
        const agent = agentByName.get(params.agent)
        if (!agent)
          throw new Error(
            `Unknown subagent: ${params.agent}\n\n${formatAgentList(discovery)}`,
          )
        const result = await runSingleAgent(
          ctx.cwd,
          agent,
          params.task,
          params.cwd,
          signal,
          (partial) => {
            onUpdate?.({
              content: [
                { type: "text", text: partial.output || "(running...)" },
              ],
              details: makeDetails("single", [partial]),
            })
          },
        )
        if (result.exitCode !== 0 || result.errorMessage) {
          throw new Error(
            result.errorMessage ||
              result.stderr ||
              result.output ||
              `Subagent ${agent.name} failed`,
          )
        }
        return {
          content: [
            { type: "text" as const, text: result.output || "(no output)" },
          ],
          details: makeDetails("single", [result]),
        }
      }

      const tasks = (params.tasks ?? []) as TaskInput[]
      if (tasks.length > MAX_PARALLEL_TASKS) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Too many parallel tasks (${tasks.length}). Max is ${MAX_PARALLEL_TASKS}.`,
            },
          ],
          details: makeDetails("parallel", []),
        }
      }

      const placeholders: SingleResult[] = tasks.map((task) => ({
        agent: task.agent,
        task: task.task,
        cwd: task.cwd ?? ctx.cwd,
        exitCode: -1,
        messages: [],
        stderr: "",
        output: "",
      }))
      const concurrency = Math.max(
        1,
        Math.min(
          MAX_CONCURRENCY,
          Math.floor(params.concurrency ?? MAX_CONCURRENCY),
        ),
      )

      const emitParallelUpdate = (): void => {
        const done = placeholders.filter(
          (result) => result.exitCode !== -1,
        ).length
        onUpdate?.({
          content: [
            {
              type: "text",
              text: `Parallel subagents: ${done}/${placeholders.length} done`,
            },
          ],
          details: makeDetails("parallel", [...placeholders]),
        })
      }

      const results = await mapWithConcurrency(
        tasks,
        concurrency,
        async (task, index) => {
          const agent = agentByName.get(task.agent)
          if (!agent) {
            const failed: SingleResult = {
              agent: task.agent,
              task: task.task,
              cwd: task.cwd ?? ctx.cwd,
              exitCode: 1,
              messages: [],
              stderr: "",
              output: "",
              errorMessage: `Unknown subagent: ${task.agent}`,
            }
            placeholders[index] = failed
            emitParallelUpdate()
            return failed
          }
          const result = await runSingleAgent(
            ctx.cwd,
            agent,
            task.task,
            task.cwd,
            signal,
            (partial) => {
              placeholders[index] = partial
              emitParallelUpdate()
            },
          )
          placeholders[index] = result
          emitParallelUpdate()
          return result
        },
      )

      const succeeded = results.filter(
        (result) => result.exitCode === 0 && !result.errorMessage,
      ).length
      const summary = results
        .map(
          (result) =>
            `${result.exitCode === 0 && !result.errorMessage ? "✓" : "✗"} ${result.agent}: ${preview(result.errorMessage ?? result.output ?? result.stderr)}`,
        )
        .join("\n")
      return {
        content: [
          {
            type: "text" as const,
            text: `Parallel subagents: ${succeeded}/${results.length} succeeded\n\n${summary}`,
          },
        ],
        details: makeDetails("parallel", results),
      }
    },

    renderCall(args, theme) {
      if (args.action === "list")
        return new Text(
          theme.fg("toolTitle", theme.bold("subagent list")),
          0,
          0,
        )
      if (args.tasks?.length) {
        return new Text(
          `${theme.fg("toolTitle", theme.bold("subagent parallel"))} ${theme.fg("accent", `${args.tasks.length} tasks`)}`,
          0,
          0,
        )
      }
      return new Text(
        `${theme.fg("toolTitle", theme.bold("subagent"))} ${theme.fg("accent", args.agent ?? "...")}`,
        0,
        0,
      )
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as SubagentDetails | undefined
      if (!details || details.mode === "list") {
        const text = result.content[0]
        return new Text(text?.type === "text" ? text.text : "", 0, 0)
      }
      if (details.mode === "single" && details.results[0]) {
        return renderSingle(details.results[0], expanded, theme)
      }

      const succeeded = details.results.filter(
        (item) => item.exitCode === 0 && !item.errorMessage,
      ).length
      const icon =
        succeeded === details.results.length
          ? theme.fg("success", "✓")
          : theme.fg("warning", "◐")
      if (!expanded) {
        const lines = [
          `${icon} ${theme.fg("toolTitle", theme.bold("parallel"))} ${theme.fg("accent", `${succeeded}/${details.results.length}`)}`,
        ]
        for (const item of details.results) {
          const itemIcon =
            item.exitCode === -1
              ? theme.fg("warning", "…")
              : item.exitCode === 0 && !item.errorMessage
                ? theme.fg("success", "✓")
                : theme.fg("error", "✗")
          lines.push(
            `${itemIcon} ${theme.fg("accent", item.agent)}: ${theme.fg("toolOutput", preview(item.errorMessage ?? item.output ?? item.stderr))}`,
          )
        }
        lines.push(theme.fg("muted", "(expand for full output)"))
        return new Text(lines.join("\n"), 0, 0)
      }

      const container = new Container()
      container.addChild(
        new Text(
          `${icon} ${theme.fg("toolTitle", theme.bold("parallel"))} ${theme.fg("accent", `${succeeded}/${details.results.length}`)}`,
          0,
          0,
        ),
      )
      for (const item of details.results) {
        container.addChild(new Spacer(1))
        container.addChild(renderSingle(item, true, theme))
      }
      return container
    },
  })
}
