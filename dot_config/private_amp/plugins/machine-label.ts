import type { PluginAPI } from "@ampcode/plugin";

export const description =
  "Labels each thread with the machine that runs it (macbook or box).";

export default function (amp: PluginAPI) {
  // Same rule as `agent_machine` in dot_config/mise/tasks/agents/lib.sh.
  const machine = process.platform === "darwin" ? "macbook" : "box";
  const labeled = new Set<string>();

  const label = async (
    threadId: string,
    thread: { addLabels(labels: string[]): Promise<string[]> },
  ) => {
    if (labeled.has(threadId)) return;
    labeled.add(threadId);
    try {
      await thread.addLabels([machine]);
    } catch (error) {
      labeled.delete(threadId);
      amp.logger.log(`machine-label: failed for ${threadId}: ${error}`);
    }
  };

  // agent.start covers threads that were already running when the plugin loaded.
  amp.on("session.start", (event, ctx) => label(event.thread.id, ctx.thread));
  amp.on("agent.start", (event, ctx) => {
    void label(event.thread.id, ctx.thread);
  });
}
