import assert from "node:assert/strict";
import rtkPlugin from "../dot_config/private_amp/plugins/rtk.ts";

interface ToolCall {
  tool: string;
  input: Record<string, unknown>;
}

type Handler = (event: unknown, context: unknown) => Promise<unknown>;

function createHarness(result: { exitCode: number; stdout: string }) {
  let handler: Handler | undefined;
  const commands: unknown[] = [];

  const amp = {
    on(_event: string, callback: unknown) {
      handler = callback as Handler;
    },
    helpers: {
      shellCommandFromToolCall(event: unknown) {
        if (typeof event !== "object" || event === null) return null;
        const call = event as ToolCall;
        if (call.tool !== "shell_command" && call.tool !== "Bash") return null;
        const command = call.input.command;
        return typeof command === "string" ? { command } : null;
      },
    },
    logger: { log() {} },
  };

  rtkPlugin(amp as never);
  assert(handler);

  return {
    commands,
    call(event: ToolCall) {
      const context = {
        $: async (_strings: TemplateStringsArray, ...values: unknown[]) => {
          commands.push(values[0]);
          return { ...result, stderr: "" };
        },
      };
      return handler!(event, context);
    },
  };
}

async function main() {
  const rewriteHarness = createHarness({ exitCode: 3, stdout: "rtk git status\n" });
  const rewritten = await rewriteHarness.call({
    tool: "shell_command",
    input: { command: "git status", workdir: "/repo" },
  });
  assert.deepEqual(rewritten, {
    action: "modify",
    input: { command: "rtk git status", workdir: "/repo" },
  });
  assert.deepEqual(rewriteHarness.commands, ["git status"]);

  const passthroughHarness = createHarness({ exitCode: 1, stdout: "" });
  const passthrough = await passthroughHarness.call({
    tool: "shell_command",
    input: { command: "printf rtk-test" },
  });
  assert.deepEqual(passthrough, { action: "allow" });

  const disabledHarness = createHarness({ exitCode: 3, stdout: "rtk git status\n" });
  const previousDisabled = process.env.RTK_DISABLED;
  process.env.RTK_DISABLED = "1";
  try {
    const disabled = await disabledHarness.call({
      tool: "shell_command",
      input: { command: "git status" },
    });
    assert.deepEqual(disabled, { action: "allow" });
    assert.deepEqual(disabledHarness.commands, []);
  } finally {
    if (previousDisabled === undefined) delete process.env.RTK_DISABLED;
    else process.env.RTK_DISABLED = previousDisabled;
  }

  console.log("Amp RTK plugin checks passed");
}

await main();
