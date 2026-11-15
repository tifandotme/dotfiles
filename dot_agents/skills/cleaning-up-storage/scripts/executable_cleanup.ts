#!/usr/bin/env bun
import { spawnSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  realpathSync,
  rmdirSync,
  statfsSync,
} from "node:fs";
import { homedir, hostname, userInfo } from "node:os";
import { basename, dirname, isAbsolute, join, resolve } from "node:path";

const home = realpathSync(homedir());
const cwd = realpathSync(process.cwd());
const projects = resolve(process.env.XDG_PROJECTS_DIR || join(home, "projects"));
const args = process.argv.slice(2);
const apply = args.includes("--apply") || args.includes("--recover");
const recover = args.includes("--recover");
let selected: string | undefined;
for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === "--worktree" && args[i + 1] && !args[i + 1]!.startsWith("-")) {
    selected = realpathSync(args[++i]!);
  } else if (!["--apply", "--recover", "--check", "--help"].includes(arg!)) {
    throw new Error(`Unknown or incomplete argument: ${arg}. Use --help.`);
  }
}
if (args.includes("--help")) {
  console.log(`Storage cleanup on the execution host only.
  updater:clean                    Audit; remove nothing
  updater:clean --check            Free-space check only (exit 3 when low)
  updater:clean --apply            Clean eligible worktrees and safe caches
  updater:clean --recover          Apply only until headroom is restored
  updater:clean --apply --worktree PATH
                                  Restrict worktrees, not cache cleanup
XDG_PROJECTS_DIR narrows repository discovery. Current repository is included.
Exit: 0 success/audit, 1 failed operation, 2 busy, 3 insufficient headroom.
No Docker mutation, package removal, Trash emptying, or process stopping.`);
  process.exit(0);
}

function run(command: string, argv: string[], directory = cwd, timeout = 20000) {
  const result = spawnSync(command, argv, {
    cwd: directory,
    encoding: "utf8",
    timeout,
    maxBuffer: 32 * 1024 * 1024,
    env: {
      ...process.env,
      GIT_TERMINAL_PROMPT: "0",
      GCM_INTERACTIVE: "never",
      GH_PROMPT_DISABLED: "1",
    },
  });
  return {
    ok: result.status === 0 && !result.error,
    out: result.stdout?.trim() || "",
    error: result.stderr?.trim() || result.error?.message || "",
  };
}
function git(directory: string, ...argv: string[]) {
  return run("git", ["-C", directory, ...argv]);
}
function within(path: string, root: string) {
  return path === root || path.startsWith(root + "/");
}
function overlap(a: string, b: string) {
  return within(a, b) || within(b, a);
}
function record(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function canonical(path: string) {
  // macOS lsof can name SIP-protected files that realpath cannot inspect.
  try {
    return realpathSync(path);
  } catch {
    return path;
  }
}
function space() {
  const fs = statfsSync(cwd);
  const free = fs.bavail * fs.bsize;
  const target = Math.max(
    (process.platform === "darwin" ? 20 : 10) * 1024 ** 3,
    fs.blocks * fs.bsize * 0.1,
  );
  const inodesLow = fs.files > 0 && fs.ffree / fs.files < 0.01;
  return {
    free,
    target,
    percent: (free / (fs.blocks * fs.bsize)) * 100,
    low: free < target || inodesLow,
    inodesLow,
  };
}
function gib(bytes: number) {
  return `${(bytes / 1024 ** 3).toFixed(2)} GiB`;
}
function reportSpace(label: string) {
  const s = space();
  console.log(
    `${label}: ${hostname()} (${process.platform}), ${cwd}: ${gib(s.free)} free (${s.free} bytes, ${s.percent.toFixed(1)}%); target ${gib(s.target)}${s.inodesLow ? "; low free inodes" : ""}`,
  );
}
reportSpace("Before");
if (args.includes("--check")) {
  if (args.length !== 1) throw new Error("Use --check alone.");
  process.exit(space().low ? 3 : 0);
}
if (recover && !space().low) {
  console.log("Headroom is sufficient. Nothing removed.");
  process.exit(0);
}
const filesystem = run("df", ["-h", cwd]);
if (filesystem.ok) console.log(filesystem.out);

// mkdir is atomic on Linux and macOS. Never steal a lock from another invocation.
const state = join(process.env.XDG_STATE_HOME || join(home, ".local/state"), "storage-cleanup");
const lock = join(state, "lock");
if (apply) {
  mkdirSync(state, { recursive: true, mode: 0o700 });
  try {
    mkdirSync(lock);
  } catch (error) {
    if (record(error) && error.code === "EEXIST") {
      console.error(
        `Cleanup is busy. If its owner crashed, confirm no cleanup is running before removing ${lock}.`,
      );
      process.exit(2);
    }
    throw error;
  }
  process.on("exit", () => rmdirSync(lock));
  for (const signal of ["SIGINT", "SIGTERM"] as const) process.on(signal, () => process.exit(1));
}
let failed = false;

function activity() {
  const files = run("lsof", ["-n", "-P", "-Fpcn"]);
  const processes = run("ps", ["-u", String(userInfo().uid), "-o", "pid=", "-o", "comm="]);
  const names = processes.out
    .split("\n")
    .filter((line) => Number(line.trim().split(/\s+/)[0]) !== process.pid)
    .map((line) => basename(line.trim().replace(/^\d+\s+/, "")));
  const paths = files.out
    .split("\n")
    .filter((line) => line.startsWith("n/"))
    .map((line) => line.slice(1).replace(/ \(deleted\)$/, ""))
    .map(canonical);
  return { files, processes, names, paths };
}
function processReason(path: string, scan: ReturnType<typeof activity>) {
  if (
    !scan.files.ok ||
    !scan.processes.ok ||
    !/^p\d+$/m.test(scan.files.out) ||
    !scan.processes.out
  )
    return "process scan failed or timed out";
  // Preserve the prior audit's handling of lsof warnings for unrelated mounts.
  for (const line of scan.files.error.split("\n").filter(Boolean)) {
    if (line.includes("WARNING: can't stat()")) {
      const mount = line.trim().split(/\s+/).at(-1)!.replace(/\/$/, "") || "/";
      if (!overlap(path, mount)) continue;
    }
    if (line.includes("Output information may be incomplete")) continue;
    return "process scan incomplete";
  }
  if (scan.paths.some((open) => within(open, path)))
    return "open files or process working directory";
  return "";
}
function sessions(scan: ReturnType<typeof activity>) {
  const protectedPaths = [cwd];
  let error = "";
  if (scan.names.some((name) => name.startsWith("tmux"))) {
    const panes = run("tmux", ["list-panes", "-a", "-F", "#{pane_current_path}"]);
    if (!panes.ok || !panes.out || panes.out.split("\n").some((path) => !isAbsolute(path)))
      error = "tmux session inventory unavailable";
    else protectedPaths.push(...panes.out.split("\n"));
  }
  if (scan.names.includes("amp")) {
    const runners = run("amp", ["runner", "list", "--json"]);
    try {
      const data: unknown = JSON.parse(runners.out);
      if (!runners.ok || !record(data) || !Array.isArray(data.runners)) throw new Error();
      for (const runner of data.runners) {
        if (!record(runner) || typeof runner.workingDirectory !== "string") throw new Error();
        // Served directories only fill the new-thread picker and outlive archived threads.
        protectedPaths.push(runner.workingDirectory);
      }
      // A runner from another account may not appear in this CLI's response.
      // Keep the working directory of every thread either account's runners serve.
      const root = join(process.env.XDG_DATA_HOME || join(home, ".local/share"), "amp");
      const roots = [join(root, "runner")];
      const accounts = join(root, "accounts");
      if (existsSync(accounts))
        for (const entry of readdirSync(accounts)) roots.push(join(accounts, entry, "runner"));
      for (const dir of roots.filter(existsSync))
        for (const file of readdirSync(dir).filter((file) => file.endsWith(".json"))) {
          const state: unknown = JSON.parse(readFileSync(join(dir, file), "utf8"));
          if (
            !record(state) ||
            typeof state.workingDirectory !== "string" ||
            !record(state.servedThreadWorkingDirectories)
          )
            throw new Error();
          for (const path of [
            state.workingDirectory,
            ...Object.values(state.servedThreadWorkingDirectories),
          ]) {
            if (typeof path !== "string" || !isAbsolute(path)) throw new Error();
            protectedPaths.push(path);
          }
        }
    } catch {
      error = "Amp runner/session inventory unavailable";
    }
  }
  // An unarchived thread keeps its checkout even while its runner sleeps it.
  // Each Amp account lists its own threads; the work account is selected by mise.
  const lists = [["amp"]];
  if (existsSync(join(projects, "work")))
    lists.push(["mise", "exec", "-C", join(projects, "work"), "--", "amp"]);
  for (const [command, ...prefix] of lists) {
    const threads = run(command!, [...prefix, "threads", "list", "--json", "--limit", "1000"]);
    try {
      const data: unknown = JSON.parse(threads.out);
      if (!threads.ok || !Array.isArray(data)) throw new Error();
      for (const thread of data) {
        if (!record(thread)) throw new Error();
        if (typeof thread.tree === "string" && thread.tree.startsWith("file://"))
          protectedPaths.push(decodeURIComponent(thread.tree.slice(7)));
      }
    } catch {
      error = "Amp thread inventory unavailable";
    }
  }
  return {
    protectedPaths: protectedPaths.map(canonical),
    error,
  };
}
function activityReason(path: string, scan: ReturnType<typeof activity>, session = sessions(scan)) {
  if (session.error) return session.error;
  if (session.protectedPaths.some((active) => within(active, path)))
    return "runner-registered directory or terminal session (including idle)";
  return processReason(path, scan);
}

interface Worktree {
  path: string;
  head: string;
  branch: string;
  locked: boolean;
  primary: string;
}
function worktrees(repo: string): Worktree[] {
  const result = git(repo, "worktree", "list", "--porcelain", "-z");
  if (!result.ok) throw new Error(`Cannot list worktrees: ${repo}`);
  const trees = result.out
    .split("\0\0")
    .filter(Boolean)
    .map((block) => {
      const fields = block.split("\0");
      return {
        path: fields.find((line) => line.startsWith("worktree "))?.slice(9) || "",
        head: fields.find((line) => line.startsWith("HEAD "))?.slice(5) || "",
        branch: fields.find((line) => line.startsWith("branch "))?.slice(7) || "",
        locked: fields.some((line) => line === "locked" || line.startsWith("locked ")),
        primary: "",
      };
    });
  for (const tree of trees) tree.primary = trees[0]!.path;
  return trees;
}
const repos = new Map<string, string>();
function addRepo(path: string) {
  const common = git(path, "rev-parse", "--path-format=absolute", "--git-common-dir");
  if (common.ok) repos.set(common.out, path);
}
addRepo(cwd);
if (selected) addRepo(selected);
let visited = 0;
function discover(path: string) {
  if (++visited > 10000)
    throw new Error("Repository discovery exceeded 10000 directories. Narrow XDG_PROJECTS_DIR.");
  if (existsSync(join(path, ".git"))) {
    addRepo(path);
    return;
  }
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    if (
      entry.isDirectory() &&
      !entry.name.startsWith(".") &&
      !["node_modules", "vendor", "target", "dist", "build"].includes(entry.name)
    )
      discover(join(path, entry.name));
  }
}
if (existsSync(projects)) discover(projects);

function refresh(repo: string) {
  if (!git(repo, "fetch", "--quiet", "origin").ok) return "";
  const remote = git(repo, "ls-remote", "origin", "HEAD");
  const head = remote.out.match(/^([0-9a-f]{40,64})\s+HEAD$/)?.[1];
  return remote.ok && head && git(repo, "cat-file", "-e", `${head}^{commit}`).ok ? head : "";
}
function eligibility(
  tree: Worktree,
  base: string,
  scan: ReturnType<typeof activity>,
  session = sessions(scan),
) {
  if (!existsSync(tree.path)) return "missing checkout; registration only";
  const path = realpathSync(tree.path);
  if (tree.path === tree.primary) return "primary checkout";
  if (within(cwd, path)) return "current checkout or its parent";
  if (tree.locked) return "locked worktree";
  if (!base) return "remote refresh/default branch failed";
  const process = activityReason(path, scan, session);
  if (process) return process;
  const status = git(
    path,
    "status",
    "--porcelain",
    "--untracked-files=all",
    "--ignore-submodules=none",
  );
  if (!status.ok || status.out) return "dirty/untracked files or status failed";
  const flags = git(path, "ls-files", "-v", "-z");
  if (!flags.ok || flags.out.split("\0").some((file) => /^[a-zS]/.test(file)))
    return "index hides tracked changes; review manually";
  const ignored = git(path, "ls-files", "--others", "--ignored", "--exclude-standard", "-z");
  if (
    !ignored.ok ||
    ignored.out
      .split("\0")
      .some((file) => file && !/(^|\/)node_modules\//.test(file) && !file.startsWith(".amp/in/"))
  )
    return "sensitive ignored files or ignored-file scan failed";
  const url = git(path, "remote", "get-url", "origin");
  let mergedPR = false;
  // A detached HEAD has no PR; only ancestry on the remote base counts.
  if (tree.branch && /github\.com[:/]/.test(url.out)) {
    const prs = run(
      "gh",
      [
        "pr",
        "list",
        "--head",
        tree.branch.replace(/^refs\/heads\//, ""),
        "--state",
        "all",
        "--limit",
        "100",
        "--json",
        "state,headRefOid",
      ],
      path,
    );
    try {
      const data: unknown = JSON.parse(prs.out);
      if (
        !prs.ok ||
        !Array.isArray(data) ||
        !data.every(
          (pr) => record(pr) && typeof pr.state === "string" && typeof pr.headRefOid === "string",
        )
      )
        return "PR lookup failed";
      if (data.some((pr) => pr.state === "OPEN")) return "open PR";
      mergedPR = data.some((pr) => pr.state === "MERGED" && pr.headRefOid === tree.head);
    } catch {
      return "PR lookup failed";
    }
  }
  if (!git(path, "merge-base", "--is-ancestor", tree.head, base).ok && !mergedPR)
    return "no merge evidence for this exact HEAD";
  if (
    git(path, "rev-parse", "HEAD").out !== tree.head ||
    git(path, "symbolic-ref", "HEAD").out !== tree.branch
  )
    return "HEAD/branch changed during checks";
  return "";
}
function size(path: string) {
  const result = run("du", ["-skx", path], cwd, 30000);
  const kb = Number(result.out.split(/\s+/)[0]);
  return result.ok && Number.isFinite(kb) ? kb * 1024 : -1;
}
const scan = activity();
const session = sessions(scan);
const candidates: (Worktree & { bytes: number })[] = [];
console.log("\nWorktrees (size includes allowed ignored dependencies and .amp/in scratch):");
for (const repo of repos.values()) {
  const base = refresh(repo);
  for (const tree of worktrees(repo)) {
    if (selected && tree.path !== selected) continue;
    const reason = eligibility(tree, base, scan, session);
    const bytes = existsSync(tree.path) ? size(tree.path) : -1;
    console.log(
      `${reason ? "keep" : "eligible"}\t${bytes < 0 ? "size unknown" : gib(bytes)}\t${tree.path}\t${reason || "merged and inactive"}`,
    );
    // Size only orders candidates; a failed scan must not block cleanup.
    if (!reason) candidates.push({ ...tree, bytes: Math.max(bytes, 0) });
  }
}

const cacheSpecs = [
  {
    tool: "bun",
    query: ["pm", "cache"],
    clean: ["pm", "cache", "rm"],
    paths: [".bun/install/cache", ".local/share/bun/install/cache"],
    owners: /^(bun|node|npm|pnpm|yarn)$/,
  },
  {
    tool: "npm",
    query: ["config", "get", "cache"],
    clean: ["cache", "clean", "--force"],
    paths: [".npm", ".cache/npm"],
    owners: /^(bun|node|npm|pnpm|yarn)$/,
  },
  {
    tool: "uv",
    query: ["cache", "dir"],
    clean: ["cache", "prune"],
    paths: [".cache/uv", "Library/Caches/uv"],
    owners: /^(uv|uvx|python[\d.]*)$/,
  },
  {
    tool: "go",
    query: ["env", "GOCACHE"],
    clean: ["clean", "-cache"],
    paths: [".cache/go-build", "Library/Caches/go-build"],
    owners: /^(go|gopls)$/,
  },
];
function cacheReason(
  path: string,
  spec: (typeof cacheSpecs)[number],
  scan: ReturnType<typeof activity>,
) {
  if (!spec.paths.some((expected) => path === join(home, expected)))
    return "nonstandard cache path; review manually";
  for (let dir = path; dir !== home; dir = dirname(dir)) {
    if (lstatSync(dir).isSymbolicLink()) return "symlinked cache path";
  }
  if (scan.names.some((name) => spec.owners.test(name))) return "cache owner is running";
  return processReason(path, scan);
}
console.log("\nSafe cache allowlist:");
const caches: { spec: (typeof cacheSpecs)[number]; path: string; bytes: number }[] = [];
for (const spec of cacheSpecs) {
  const location = run(spec.tool, spec.query, home);
  if (!location.ok || !isAbsolute(location.out) || !existsSync(location.out)) continue;
  const path = location.out;
  const reason = cacheReason(path, spec, scan);
  const bytes = size(path);
  console.log(
    `${reason ? "keep" : "eligible"}\t${bytes < 0 ? "size unknown" : gib(bytes)}\t${path}\t${reason || spec.clean.join(" ")}`,
  );
  if (!reason) caches.push({ spec, path, bytes: Math.max(bytes, 0) });
}
console.log("\nDocker (report only; reclaimable does not mean safe):");
const docker = run("docker", ["system", "df"]);
console.log(
  docker.ok ? docker.out : "Docker unavailable or inventory timed out; no Docker changes.",
);
if (process.platform === "darwin") {
  for (const path of [
    "Library/Developer/Xcode/DerivedData",
    "Library/Developer/Xcode/Archives",
    "Library/Developer/CoreSimulator",
    ".colima",
  ]) {
    if (existsSync(join(home, path)))
      console.log(`review only\t${gib(size(join(home, path)))}\t${join(home, path)}`);
  }
}

if (apply) {
  for (const tree of candidates.sort((a, b) => b.bytes - a.bytes)) {
    if (recover && !space().low) break;
    if (
      statfsSync(tree.path).type !== statfsSync(cwd).type ||
      lstatSync(tree.path).dev !== lstatSync(cwd).dev
    ) {
      console.log(`keep\t${tree.path}\tdifferent filesystem from recovery target`);
      continue;
    }
    const fresh = worktrees(tree.primary).find((fresh) => fresh.path === tree.path);
    let reason =
      !fresh || fresh.head !== tree.head || fresh.branch !== tree.branch
        ? "HEAD/branch/registration changed"
        : eligibility(fresh, refresh(tree.primary), activity());
    // Network/PR checks can take time. Recheck ownership after them, before removal.
    if (!reason) reason = activityReason(realpathSync(tree.path), activity());
    if (reason) {
      console.log(`keep\t${tree.path}\t${reason}`);
      continue;
    }
    const removed = git(tree.primary, "worktree", "remove", "--", tree.path);
    if (!removed.ok) {
      failed = true;
      console.error(`Removal refused: ${tree.path}: ${removed.error}`);
      continue;
    }
    console.log(`removed\t${tree.path}`);
    if (tree.branch && git(tree.primary, "rev-parse", "--verify", tree.branch).out === tree.head) {
      // Compare-and-delete avoids deleting a branch that moved after removal.
      const deleted = git(tree.primary, "update-ref", "-d", tree.branch, tree.head);
      if (!deleted.ok) {
        failed = true;
        console.error(`Branch retained: ${tree.branch}: ${deleted.error}`);
      }
    }
    reportSpace("After worktree");
  }
  for (const cache of caches.sort((a, b) => b.bytes - a.bytes)) {
    if (recover && !space().low) break;
    if (!existsSync(cache.path)) continue;
    const location = run(cache.spec.tool, cache.spec.query, home);
    const reason =
      !location.ok || location.out !== cache.path
        ? "cache location changed"
        : cacheReason(cache.path, cache.spec, activity());
    if (reason) {
      console.log(`keep\t${cache.path}\t${reason}`);
      continue;
    }
    if (lstatSync(cache.path).dev !== lstatSync(cwd).dev) {
      console.log(`keep\t${cache.path}\tdifferent filesystem`);
      continue;
    }
    const result = run(cache.spec.tool, cache.spec.clean, home, 120000);
    if (!result.ok) {
      failed = true;
      console.error(`Cache cleanup failed: ${cache.path}: ${result.error}`);
    } else console.log(`cleaned\t${cache.path}`);
    reportSpace("After cache");
  }
} else
  console.log(
    "\nAudit only. Nothing removed. Use --recover for bounded recovery or --apply for all eligible items.",
  );
reportSpace("After");
if (space().low)
  console.log(
    "Headroom target not reached. Review reported consumers or increase capacity; do not broaden deletion automatically.",
  );
process.exitCode = failed ? 1 : apply && space().low ? 3 : 0;
