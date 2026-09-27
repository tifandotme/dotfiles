import type { PluginAPI } from "@ampcode/plugin";

export default function (amp: PluginAPI) {
  let hasWarned = false;

  amp.on("tool.call", async (event, ctx) => {
    if (process.env.RTK_DISABLED === "1") {
      return { action: "allow" };
    }

    const shell = amp.helpers.shellCommandFromToolCall(event);
    const command = event.input.command;

    if (
      !shell ||
      typeof command !== "string" ||
      command !== shell.command ||
      /^\s*rtk(?:\s|$)/.test(command)
    ) {
      return { action: "allow" };
    }

    try {
      const result = await ctx.$`rtk rewrite ${command}`;
      const rewritten = result.stdout.trim();

      if (
        (result.exitCode !== 0 && result.exitCode !== 3) ||
        !rewritten ||
        rewritten === command
      ) {
        return { action: "allow" };
      }

      return {
        action: "modify",
        input: { ...event.input, command: rewritten },
      };
    } catch {
      if (!hasWarned) {
        hasWarned = true;
        amp.logger.log("rtk rewrite failed; passing the shell command through unchanged");
      }
      return { action: "allow" };
    }
  });
}
