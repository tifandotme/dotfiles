import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, sep } from "node:path";
import type { PluginAPI } from "@ampcode/plugin";

export const description =
  "Rewrites shell commands with RTK and activates mise for work repositories.";

const workRoot = join(homedir(), "projects", "work");

function isWorkDirectory(value: unknown): value is string {
  if (typeof value !== "string" || !isAbsolute(value)) return false;

  try {
    const root = realpathSync(workRoot);
    const directory = realpathSync(value);
    return directory === root || directory.startsWith(`${root}${sep}`);
  } catch {
    return false;
  }
}

function quoteForBash(value: string): string {
  return `'${value.replaceAll("'", "'\\''")}'`;
}

export default function (amp: PluginAPI) {
  let hasWarned = false;

  amp.on("tool.call", async (event, ctx) => {
    const shell = amp.helpers.shellCommandFromToolCall(event);
    const command = event.input.command;

    if (
      !shell ||
      typeof command !== "string" ||
      command !== shell.command
    ) {
      return { action: "allow" };
    }

    const inWorkDirectory = isWorkDirectory(event.input.workdir);
    const alreadyUsesMise =
      inWorkDirectory && /^\s*mise\s+exec(?:\s|$)/.test(command);
    let rewritten = command;
    if (
      process.env.RTK_DISABLED !== "1" &&
      !/^\s*rtk(?:\s|$)/.test(command) &&
      !alreadyUsesMise
    ) {
      try {
        const result = await ctx.$`rtk rewrite ${command}`;
        const candidate = result.stdout.trim();

        if (
          (result.exitCode === 0 || result.exitCode === 3) &&
          candidate &&
          candidate !== command
        ) {
          rewritten = candidate;
        }
      } catch {
        if (!hasWarned) {
          hasWarned = true;
          amp.logger.log("rtk rewrite failed; leaving the command unchanged");
        }
      }
    }

    if (inWorkDirectory && !alreadyUsesMise) {
      rewritten = `mise exec -- bash -c ${quoteForBash(rewritten)}`;
    }

    if (rewritten === command) return { action: "allow" };

    return {
      action: "modify",
      input: { ...event.input, command: rewritten },
    };
  });
}
