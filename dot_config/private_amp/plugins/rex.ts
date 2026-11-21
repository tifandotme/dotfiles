import type { PluginAPI } from "@ampcode/plugin";

export const description =
  "Tells the agent which Rex session and pane it runs in, once per thread.";

export default function (amp: PluginAPI) {
  const injected = new Set<string>();

  // Rex has no native Amp hook. `rex __internal session-start` prints the
  // same prompt Rex gives Claude Code, and nothing outside a Rex terminal.
  amp.on("agent.start", async (event, ctx) => {
    const threadId = event.thread.id;
    if (injected.has(threadId)) return;
    injected.add(threadId);

    try {
      const result = await ctx.$`rex __internal session-start --agent amp`;
      const content = result.stdout.trim();
      if (result.exitCode !== 0 || !content) return;
      return { message: { content, display: false } };
    } catch {
      return;
    }
  });
}
