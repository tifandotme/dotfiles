import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { promisify } from "node:util";
import type { PluginAPI } from "@ampcode/plugin";

export const description =
  "Creates create_thread worktrees with git twig (copy-on-write) instead of the runner's git worktree add.";

type Shell = (
  strings: TemplateStringsArray,
  ...values: unknown[]
) => Promise<{ exitCode: number; stdout: string }>;

const execFileAsync = promisify(execFile);

// Twig only saves disk on macOS (APFS) or a Linux reflink filesystem. Elsewhere it
// falls back to stock git and the runner's own worktree path is better.
async function canClone(repo: string): Promise<boolean> {
  if (process.platform === "darwin") return true;
  try {
    const { stdout } = await execFileAsync("findmnt", ["-no", "FSTYPE", "-T", repo]);
    return ["xfs", "btrfs"].includes(stdout.trim());
  } catch {
    return false;
  }
}

export default function (amp: PluginAPI) {
  amp.on("tool.call", async (event, ctx) => {
    const name = event.input.worktree;
    if (
      event.tool !== "create_thread" ||
      event.input.executor !== "runner" ||
      typeof name !== "string" ||
      !/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(name)
    ) {
      return { action: "allow" };
    }

    const $ = ctx.$ as unknown as Shell;
    const run = async (parts: TemplateStringsArray, ...values: unknown[]) => {
      try {
        return await $(parts, ...values);
      } catch {
        return { exitCode: 1, stdout: "" };
      }
    };
    const out = async (parts: TemplateStringsArray, ...values: unknown[]) => {
      const result = await run(parts, ...values);
      return result.exitCode === 0 ? result.stdout.trim() : null;
    };

    const dir =
      typeof event.input.working_directory === "string"
        ? event.input.working_directory
        : process.cwd();

    // Only main checkouts get worktrees, and git twig must exist; otherwise let
    // the runner create the worktree itself.
    const gitDir = await out`git -C ${dir} rev-parse --absolute-git-dir`;
    const commonDir = await out`git -C ${dir} rev-parse --path-format=absolute --git-common-dir`;
    const repo = await out`git -C ${dir} rev-parse --show-toplevel`;
    if (!gitDir || gitDir !== commonDir || !repo) return { action: "allow" };
    if (!(await canClone(repo))) return { action: "allow" };
    if ((await run`git twig -h`).exitCode !== 0) return { action: "allow" };

    // Same naming rules as the runner: <repo>-<name>, adding -2, -3 on a clash.
    let suffix = "";
    for (let n = 2; n < 100; n++) {
      const branchTaken =
        (await run`git -C ${repo} show-ref --verify --quiet refs/heads/${name + suffix}`).exitCode === 0;
      if (!existsSync(`${repo}-${name}${suffix}`) && !branchTaken) break;
      suffix = `-${n}`;
    }
    const branch = name + suffix;
    const dest = `${repo}-${branch}`;

    // Start at the upstream tip when HEAD is behind it, like the runner does.
    let start = "HEAD";
    // A stalled remote must not hang create_thread, so the fetch gets 20 seconds.
    const fetched = await execFileAsync("git", ["-C", repo, "fetch", "--quiet"], {
      timeout: 20_000,
    }).then(
      () => true,
      () => false,
    );
    if (fetched) {
      const upstream = await out`git -C ${repo} rev-parse --verify --quiet @{u}`;
      if (
        upstream &&
        (await run`git -C ${repo} merge-base --is-ancestor HEAD ${upstream}`).exitCode === 0
      ) {
        start = upstream;
      }
    }

    const created = await run`git -C ${repo} twig new -b ${branch} ${dest} ${start}`;
    if (created.exitCode !== 0) return { action: "allow" };

    const { worktree: _worktree, ...input } = event.input;
    return {
      action: "modify",
      input: { ...input, working_directory: dest },
    };
  });
}
