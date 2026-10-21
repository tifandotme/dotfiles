import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import shellCommandPlugin from "../dot_config/private_amp/plugins/shell-command.ts";

interface ToolCall {
  tool: string;
  input: Record<string, unknown>;
}

type Handler = (event: unknown, context: unknown) => Promise<unknown>;

function modifiedInput(result: unknown): Record<string, unknown> {
  assert(result && typeof result === "object" && "input" in result);
  const input = result.input;
  assert(input && typeof input === "object" && !Array.isArray(input));
  return input as Record<string, unknown>;
}

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

  shellCommandPlugin(amp as never);
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

  const workRoot = join(homedir(), "projects", "work");
  const hasWorkRoot = existsSync(workRoot);
  const previousDisabled = process.env.RTK_DISABLED;
  const disabledHarness = createHarness({ exitCode: 3, stdout: "rtk git status\n" });
  try {
    delete process.env.RTK_DISABLED;

    if (hasWorkRoot) {
      const explicitMiseHarness = createHarness({
        exitCode: 3,
        stdout: "rtk mise exec -- gws --help\n",
      });
      const explicitMise = await explicitMiseHarness.call({
        tool: "shell_command",
        input: { command: "mise exec -- gws --help", workdir: workRoot },
      });
      assert.deepEqual(explicitMise, { action: "allow" });
      assert.deepEqual(explicitMiseHarness.commands, []);

      const rewriteAndWrapHarness = createHarness({
        exitCode: 3,
        stdout: "rtk git status\n",
      });
      const rewriteAndWrap = await rewriteAndWrapHarness.call({
        tool: "shell_command",
        input: { command: "git status", workdir: workRoot },
      });
      const rewrittenInput = modifiedInput(rewriteAndWrap);
      assert(typeof rewrittenInput.command === "string");
      assert.match(rewrittenInput.command, /^mise exec -- bash -c /);
      assert.match(rewrittenInput.command, /rtk git status/);
      assert.deepEqual(rewriteAndWrapHarness.commands, ["git status"]);
    }

    process.env.RTK_DISABLED = "1";
    const disabled = await disabledHarness.call({
      tool: "shell_command",
      input: { command: "git status" },
    });
    assert.deepEqual(disabled, { action: "allow" });
    assert.deepEqual(disabledHarness.commands, []);

    if (hasWorkRoot) {
      const workHarness = createHarness({ exitCode: 3, stdout: "" });
      const wrapped = await workHarness.call({
        tool: "shell_command",
        input: {
          command: `printf '%s' "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR"`,
          workdir: workRoot,
          timeout_ms: 1000,
        },
      });
      const wrappedInput = modifiedInput(wrapped);
      assert.equal(wrappedInput.workdir, workRoot);
      assert.equal(wrappedInput.timeout_ms, 1000);
      assert(typeof wrappedInput.command === "string");
      const command = wrappedInput.command;
      assert.match(command, /^mise exec -- bash -c /);

      const smokeTest = spawnSync("bash", ["-c", command], {
        cwd: workRoot,
        encoding: "utf8",
      });
      assert.equal(smokeTest.status, 0, smokeTest.stderr);
      assert.equal(
        smokeTest.stdout,
        join(homedir(), ".config", "gws-hadl"),
      );

      const outsideWork = await workHarness.call({
        tool: "shell_command",
        input: { command: "printf outside", workdir: "/tmp" },
      });
      assert.deepEqual(outsideWork, { action: "allow" });

      const rtkInWork = await workHarness.call({
        tool: "shell_command",
        input: { command: "rtk status", workdir: workRoot },
      });
      const rtkCommand = modifiedInput(rtkInWork).command;
      assert(typeof rtkCommand === "string");
      assert.match(rtkCommand, /^mise exec -- bash -c /);
      assert.deepEqual(workHarness.commands, []);
    } else {
      console.log(`Skipping Mise smoke test: ${workRoot} does not exist`);
    }
  } finally {
    if (previousDisabled === undefined) delete process.env.RTK_DISABLED;
    else process.env.RTK_DISABLED = previousDisabled;
  }

  console.log("Amp shell command plugin checks passed");
}

await main();
