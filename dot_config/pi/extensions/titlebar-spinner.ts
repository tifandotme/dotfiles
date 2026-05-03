import path from "node:path"
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent"

const FRAMES = ["⡿", "⣟", "⣯", "⣷", "⣾", "⣽", "⣻", "⢿"]
const INTERVAL_MS = 70

function baseTitle(pi: ExtensionAPI): string {
  const cwd = path.basename(process.cwd())
  const session = pi.getSessionName()
  return session ? `π - ${session} - ${cwd}` : `π - ${cwd}`
}

export default function (pi: ExtensionAPI): void {
  let timer: ReturnType<typeof setInterval> | undefined
  let frameIndex = 0

  function stop(ctx: ExtensionContext): void {
    if (timer) {
      clearInterval(timer)
      timer = undefined
    }
    frameIndex = 0
    ctx.ui.setTitle(baseTitle(pi))
  }

  function start(ctx: ExtensionContext): void {
    stop(ctx)
    timer = setInterval(() => {
      const frame = FRAMES[frameIndex % FRAMES.length]
      ctx.ui.setTitle(`${frame} ${baseTitle(pi)}`)
      frameIndex++
    }, INTERVAL_MS)
  }

  pi.on("agent_start", async (_event, ctx) => {
    start(ctx)
  })

  pi.on("agent_end", async (_event, ctx) => {
    stop(ctx)
  })

  pi.on("session_shutdown", async (_event, ctx) => {
    stop(ctx)
  })
}
