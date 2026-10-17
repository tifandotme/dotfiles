#!/usr/bin/env bun
import assert from "node:assert/strict";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  symlinkSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { spawnSync } from "node:child_process";

const root = resolve(import.meta.dir, "..");
const picker = join(root, "dot_local/bin/executable_open-project");
const prune = join(root, "dot_local/bin/executable_prune-worktrees");
const home = realpathSync(mkdtempSync(join(tmpdir(), "worktree-check-")));

try {
  const bins = join(home, "bin");
  mkdirSync(bins);
  const log = join(home, "calls");
  const env = {
    ...process.env,
    HOME: home,
    XDG_PROJECTS_DIR: join(home, "projects"),
    XDG_CACHE_HOME: join(home, "cache"),
    HERDR_ENV: "1",
    GIT_CONFIG_GLOBAL: "/dev/null",
    GIT_CONFIG_NOSYSTEM: "1",
    PATH: bins + ":" + process.env.PATH,
    CALL_LOG: log,
  };
  const stub = `#!/usr/bin/env bun
import { appendFileSync, readFileSync } from "node:fs";
import { basename } from "node:path";
const args = process.argv.slice(2);
const name = basename(process.argv[1]);
appendFileSync(process.env.CALL_LOG, JSON.stringify([name, ...args]) + "\\n");
if (name === "fzf") {
  const rows = readFileSync(0, "utf8").trimEnd().split("\\n");
  if (args.includes("--header")) console.log(process.env.CONFIRM === "1" ? "Yes" : "Back");
  else if (process.env.SELECT === "cancel") process.exit(130);
  else console.log(rows[Number(process.env.SELECT ?? "0")]);
} else if (name === "gh") {
  console.log(JSON.stringify([{ number: 1, title: "Example", state: "OPEN", isDraft: true, baseRefName: "main", url: "https://example.test/1", statusCheckRollup: [{ conclusion: "SUCCESS" }, { status: "IN_PROGRESS" }] }]));
} else if (args[1] === "list") {
  const kind = args[0];
  let values = [];
  if (kind === "worktree") values = [{ path: args.at(-1), open_workspace_id: process.env.WORKSPACE ?? "" }];
  if (kind === "workspace") values = JSON.parse(process.env.WORKSPACES ?? "[]");
  if (kind === "agent") values = JSON.parse(process.env.AGENTS ?? "[]");
  console.log(JSON.stringify({ result: { [kind + "s"]: values } }));
}
`;
  for (const name of ["herdr", "fzf", "gh"]) {
    const path = join(bins, name);
    writeFileSync(path, stub);
    chmodSync(path, 0o755);
  }

  interface Options {
    extra?: Record<string, string>;
    stdin?: string;
  }
  function cmd(args: string[], options: Options = {}) {
    const result = spawnSync(args[0]!, args.slice(1), {
      env: { ...env, ...options.extra },
      input: options.stdin ?? "",
      encoding: "utf8",
    });
    assert.equal(
      result.status,
      0,
      JSON.stringify({ args, stdout: result.stdout, stderr: result.stderr }),
    );
    return { returncode: result.status, stdout: result.stdout, stderr: result.stderr };
  }
  function cli(entry: string, args: string[] = [], options: Options = {}) {
    return cmd([process.execPath, entry, ...args], options);
  }
  function calls() {
    return readFileSync(log, "utf8");
  }
  function callCount(action: string) {
    return calls().split(`"${action}"`).length - 1;
  }

  const repo = join(home, "projects/personal/repo space");
  const group = join(home, "projects/personal");
  mkdirSync(group, { recursive: true });
  cmd(["git", "init", "-q", "-b", "main", repo]);
  cmd([
    "git",
    "-C",
    repo,
    "-c",
    "user.name=t",
    "-c",
    "user.email=t@t",
    "commit",
    "-q",
    "--allow-empty",
    "-m",
    "init",
  ]);
  cmd(["git", "-C", repo, "update-ref", "refs/remotes/origin/main", "HEAD"]);
  cmd(["git", "-C", repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main"]);
  const wt = join(group, "repo space-feature-topic");
  cmd(["git", "-C", repo, "worktree", "add", "-q", "-b", "feature/topic", wt]);
  const rows = cli(picker, ["_rows"]).stdout;
  assert(rows.includes("feature/topic") && rows.split("create\t").length === 2);
  cli(picker, [], { extra: { SELECT: "cancel" } });
  cli(picker, [], { extra: { SELECT: "1" } });
  assert(calls().includes('"open"') && calls().includes('"--focus"'));
  cli(picker, [], { stdin: "new/topic\n" });
  assert(calls().includes(join(group, "repo space-new-topic")));
  const before = callCount("create");
  symlinkSync(join(home, "missing"), join(group, "repo space-collision"));
  cli(picker, [], { stdin: "collision\n" });
  assert.equal(callCount("create"), before);
  const preview = cli(picker, ["_preview", "worktree", wt, "feature/topic"]).stdout;
  assert(
    preview.includes("DRAFT") &&
      preview.includes("1 passed") &&
      preview.includes("1 pending") &&
      preview.includes("https://example.test/1"),
  );
  const ghCalls = callCount("gh");
  cli(picker, ["_preview", "worktree", wt, "feature/topic"]);
  assert.equal(callCount("gh"), ghCalls, "PR preview should use its cache");
  writeFileSync(join(wt, "dirty"), "x");
  cli(picker, ["_close", "worktree", repo, wt], { extra: { CONFIRM: "1" } });
  assert(existsSync(wt));
  unlinkSync(join(wt, "dirty"));
  writeFileSync(join(wt, ".gitignore"), "ignored\n");
  cmd(["git", "-C", wt, "add", ".gitignore"]);
  cmd([
    "git",
    "-C",
    wt,
    "-c",
    "user.name=t",
    "-c",
    "user.email=t@t",
    "commit",
    "-q",
    "-m",
    "ignore",
  ]);
  writeFileSync(join(wt, "ignored"), "keep");
  cli(picker, ["_close", "worktree", repo, wt], { extra: { CONFIRM: "1" } });
  assert(existsSync(wt));
  unlinkSync(join(wt, "ignored"));
  cli(picker, ["_close", "worktree", repo, wt], { extra: { CONFIRM: "1" } });
  assert(existsSync(wt), "unmerged worktree removed");
  cmd(["git", "-C", repo, "update-ref", "refs/remotes/origin/main", "feature/topic"]);
  const removesBefore = callCount("remove");
  const busy = {
    WORKSPACE: "busy",
    AGENTS: JSON.stringify([{ workspace_id: "busy", agent_status: "working" }]),
    CONFIRM: "1",
  };
  cli(picker, ["_close", "worktree", repo, wt], { extra: busy });
  assert(callCount("remove") === removesBefore && existsSync(wt));

  // Simulate an externally deleted checkout, only in this temporary HOME.
  rmSync(wt, { recursive: true });
  const workspaces = ["idle", "busy"].map((name) => ({
    workspace_id: name,
    worktree: { repo_key: join(repo, ".git"), checkout_path: join(home, name) },
  }));
  const result = cli(prune, [repo], {
    stdin: "yes\n",
    extra: { ...busy, WORKSPACES: JSON.stringify(workspaces) },
  });
  assert(
    result.stdout.includes("Removing worktrees/") &&
      result.stdout.includes("nothing changed") &&
      result.stdout.includes("Skipped"),
  );
  assert(cmd(["git", "-C", repo, "worktree", "list", "--porcelain"]).stdout.includes(wt));
  assert(!calls().includes('"close"') && !calls().includes('"remove"'));
  console.log(
    "ok: picker, PR preview/cache, creation/collision, close guards, noninteractive prune and busy workspaces",
  );
} finally {
  rmSync(home, { recursive: true, force: true });
}
