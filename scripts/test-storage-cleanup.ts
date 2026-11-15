#!/usr/bin/env bun
// Public command checks. Git and deletion are real; activity and cache tools are isolated.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  statfsSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const script = resolve(
  import.meta.dir,
  "../dot_agents/skills/cleaning-up-storage/scripts/executable_cleanup.ts",
);
const tmp = realpathSync(mkdtempSync(join(tmpdir(), "storage-cleanup-test-")));
const home = join(tmp, "home");
const bin = join(tmp, "bin");
const repo = join(home, "projects/deep/owner/repo");
const remote = join(tmp, "origin.git");
const originalGit = spawnSync("which", ["git"], { encoding: "utf8" }).stdout.trim();
mkdirSync(repo, { recursive: true });
mkdirSync(bin);
const env = {
  ...process.env,
  HOME: home,
  XDG_STATE_HOME: join(home, ".local/state"),
  XDG_DATA_HOME: join(home, ".local/share"),
  XDG_PROJECTS_DIR: join(home, "projects"),
  PATH: `${bin}:${process.env.PATH}`,
  TEST_REAL_GIT: originalGit,
  GIT_CONFIG_GLOBAL: "/dev/null",
  GIT_CONFIG_NOSYSTEM: "1",
  GIT_AUTHOR_NAME: "Cleanup test",
  GIT_AUTHOR_EMAIL: "test@example.invalid",
  GIT_COMMITTER_NAME: "Cleanup test",
  GIT_COMMITTER_EMAIL: "test@example.invalid",
};
function git(directory: string, ...args: string[]) {
  const result = spawnSync(originalGit, ["-C", directory, ...args], { env, encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trim();
}
function put(path: string, data = "keep\n") {
  mkdirSync(resolve(path, ".."), { recursive: true });
  writeFileSync(path, data);
}
const mock = `#!/usr/bin/env bash
set -euo pipefail
case "]NAME[" in
ps) printf '%s\\n' "\${TEST_PROCESSES:-1 init}" ;;
lsof)
  [[ \${TEST_SCAN_FAIL:-0} != 1 ]] || exit 1
  printf '%s\\n' "\${TEST_LSOF:-p1}"
  [[ -z \${TEST_WARNING:-} ]] || printf '%s\\n' "$TEST_WARNING" >&2 ;;
amp) [[ \${TEST_RUNNER_FAIL:-0} != 1 ]] && printf '%s\\n' "\${TEST_RUNNERS:-}" ;;
tmux) printf '%s\\n' "\${TEST_PANE:-/unrelated}" ;;
gh) [[ \${TEST_PR_FAIL:-0} != 1 ]] && printf '%s\\n' "\${TEST_PRS:-[]}" ;;
docker) [[ "$*" == 'system df' ]] || exit 99; printf 'report only\\n' ;;
bun)
  if [[ "$*" == 'pm cache' ]]; then printf '%s/.bun/install/cache\\n' "$HOME"
  elif [[ "$*" == 'pm cache rm' ]]; then rm -rf -- "$HOME/.bun/install/cache"
  else exit 99; fi ;;
npm|uv|go) exit 1 ;;
git)
  if [[ \${TEST_FETCH_FAIL:-0} == 1 && " $* " == *' fetch '* ]]; then exit 1; fi
  if [[ \${TEST_GITHUB:-0} == 1 && " $* " == *' remote get-url origin '* ]]; then printf 'https://github.com/test/repo.git\\n'; exit 0; fi
  if [[ -n \${TEST_RACE:-} && " $* " == *' fetch '* ]]; then
    count=0; [[ ! -f "$TEST_RACE.count" ]] || count=$(cat "$TEST_RACE.count")
    count=$((count + 1)); printf '%s' "$count" >"$TEST_RACE.count"
    if [[ $count == 2 ]]; then "$TEST_REAL_GIT" -C "$TEST_RACE" commit --allow-empty -qm race; fi
  fi
  exec "$TEST_REAL_GIT" "$@" ;;
esac
`;
for (const tool of ["ps", "lsof", "amp", "tmux", "gh", "docker", "bun", "npm", "uv", "go", "git"]) {
  writeFileSync(join(bin, tool), mock.replace("]NAME[", tool), { mode: 0o755 });
}
function command(args: string[] = [], extra: Record<string, string> = {}, directory = home) {
  const result = spawnSync(process.execPath, [script, ...args], {
    cwd: directory,
    env: { ...env, ...extra },
    encoding: "utf8",
  });
  assert.ok(
    [0, 3].includes(result.status!),
    `${result.status}: ${result.stderr}\n${result.stdout}`,
  );
  return result.stdout;
}
function tree(name: string) {
  const path = join(home, "projects", name);
  git(repo, "worktree", "add", "-qb", name.replaceAll(" ", "-"), path, "main");
  return path;
}
try {
  git(repo, "init", "-qb", "main");
  put(join(repo, ".gitignore"), "node_modules/\n.amp/in/\n.env\n");
  put(join(repo, "tracked"));
  git(repo, "add", ".");
  git(repo, "commit", "-qm", "initial");
  git(tmp, "init", "--bare", "-q", "--initial-branch=main", remote);
  git(repo, "remote", "add", "origin", remote);
  git(repo, "push", "-qu", "origin", "main");
  const safe = tree("safe with spaces");
  put(join(safe, "tracked"), "merged feature\n");
  git(safe, "commit", "-qam", "feature");
  git(repo, "merge", "--ff-only", "safe-with-spaces");
  git(repo, "push", "-q", "origin", "main");
  const dirty = tree("dirty");
  put(join(dirty, "tracked"), "uncommitted\n");
  const untracked = tree("untracked");
  put(join(untracked, "personal"));
  const ignored = tree("ignored");
  put(join(ignored, ".env"), "SECRET=preserve\n");
  const locked = tree("locked");
  git(repo, "worktree", "lock", locked);
  const active = tree("active");
  const idle = tree("idle");
  const unfinished = tree("unfinished");
  git(unfinished, "commit", "--allow-empty", "-qm", "unmerged");
  const hidden = tree("hidden");
  git(hidden, "update-index", "--skip-worktree", "tracked");
  put(join(hidden, "tracked"), "hidden work\n");
  put(join(safe, "node_modules/package/index.js"));
  put(join(safe, ".amp/in/result.txt"));
  const cache = join(home, ".bun/install/cache");
  put(join(cache, "download"));
  put(join(home, ".Trash/keep"));
  put(join(home, "windmill-postgres/data"));
  const alias = join(tmp, "alias");
  symlinkSync(home, alias);
  const protectedEnv = {
    TEST_LSOF: `p12\nn${join(alias, "projects/active/tracked")}`,
    TEST_PROCESSES: "1 init\n13 amp",
    TEST_RUNNERS: JSON.stringify({
      runners: [{ workingDirectory: repo, directories: [{ path: idle }] }],
    }),
  };
  const audit = command([], protectedEnv);
  assert.match(audit, /eligible\t[^\n]*safe with spaces/);
  assert.ok(!existsSync(env.XDG_STATE_HOME), "audit should not create cleanup state");
  assert.ok(existsSync(safe) && existsSync(join(cache, "download")), "audit must delete nothing");
  command(["--apply"], protectedEnv);
  assert.ok(!existsSync(safe), "merged inactive worktree should be removed");
  assert.ok(!git(repo, "branch", "--list", "safe-with-spaces"), "branch should be removed");
  for (const path of [repo, dirty, untracked, ignored, locked, active, idle, unfinished, hidden])
    assert.ok(existsSync(path), path);
  assert.equal(readFileSync(join(ignored, ".env"), "utf8"), "SECRET=preserve\n");
  assert.ok(!existsSync(cache), "allowlisted cache should be cleaned");
  assert.ok(
    existsSync(join(home, ".Trash/keep")) && existsSync(join(home, "windmill-postgres/data")),
  );

  // Each refused action still has a genuinely removable control candidate.
  const guarded = tree("guarded");
  for (const extra of [
    { TEST_SCAN_FAIL: "1" },
    { TEST_FETCH_FAIL: "1" },
    { TEST_PROCESSES: "1 herdr" },
    { TEST_PROCESSES: "1 amp", TEST_RUNNER_FAIL: "1" },
    { TEST_PROCESSES: "1 tmux: server", TEST_PANE: guarded },
    { TEST_WARNING: `lsof: WARNING: can't stat() ext4 file system ${home}` },
    { TEST_GITHUB: "1", TEST_PR_FAIL: "1" },
    { TEST_GITHUB: "1", TEST_PRS: '[{"state":"OPEN","headRefOid":"different"}]' },
  ]) {
    command(["--apply", "--worktree", guarded], extra);
    assert.ok(existsSync(guarded), JSON.stringify(extra));
  }
  command(["--apply", "--worktree", guarded], {}, guarded);
  assert.ok(existsSync(guarded), "current checkout must survive");
  command(["--apply", "--worktree", guarded], { TEST_RACE: guarded });
  assert.ok(existsSync(guarded), "changed HEAD must survive");
  assert.equal(git(guarded, "log", "-1", "--format=%s"), "race");
  const squash = tree("squash");
  git(squash, "commit", "--allow-empty", "-qm", "squashed elsewhere");
  const head = git(squash, "rev-parse", "HEAD");
  command(["--apply", "--worktree", squash], {
    TEST_GITHUB: "1",
    TEST_PRS: '[{"state":"MERGED","headRefOid":"different"}]',
  });
  assert.ok(existsSync(squash), "different PR HEAD must not count as merged");
  command(["--apply", "--worktree", squash], {
    TEST_GITHUB: "1",
    TEST_PRS: JSON.stringify([{ state: "MERGED", headRefOid: head }]),
    TEST_WARNING:
      "lsof: WARNING: can't stat() fuse file system /unrelated\nlsof: Output information may be incomplete.",
  });
  assert.ok(!existsSync(squash), "exact squash-merged HEAD should be removable");

  const recovery = tree("recovery");
  const fs = statfsSync(home);
  const minimum = (process.platform === "darwin" ? 20 : 10) * 1024 ** 3;
  const low =
    fs.bavail * fs.bsize < minimum ||
    fs.bavail / fs.blocks < 0.1 ||
    (fs.files > 0 && fs.ffree / fs.files < 0.01);
  command(["--recover", "--worktree", recovery]);
  assert.equal(existsSync(recovery), !low, "recovery should delete only while headroom is low");

  put(join(cache, "download"));
  command(["--apply"], { TEST_PROCESSES: "1 node" });
  assert.ok(existsSync(cache), "active cache owner must protect cache");
  rmSync(cache, { recursive: true });
  const documents = join(home, "Documents");
  put(join(documents, "keep"));
  symlinkSync(documents, cache);
  command(["--apply"]);
  assert.ok(existsSync(join(documents, "keep")), "symlink target must survive");
  const lock = join(env.XDG_STATE_HOME, "storage-cleanup/lock");
  mkdirSync(lock);
  const busy = spawnSync(process.execPath, [script, "--apply"], {
    cwd: home,
    env,
    encoding: "utf8",
  });
  assert.equal(busy.status, 2);
  assert.ok(existsSync(lock));
  rmSync(lock, { recursive: true });
  // Test the installed task interface without applying real dotfiles.
  const installed = join(home, ".agents/skills/cleaning-up-storage/scripts/cleanup.ts");
  mkdirSync(resolve(installed, ".."), { recursive: true });
  copyFileSync(script, installed);
  const task = spawnSync(
    "bash",
    [resolve(import.meta.dir, "../dot_config/mise/tasks/updater/executable_clean"), "--check"],
    {
      cwd: home,
      env: { ...env, PATH: `${resolve(process.execPath, "..")}:${env.PATH}` },
      encoding: "utf8",
    },
  );
  assert.ok([0, 3].includes(task.status!), task.stderr);
  assert.match(task.stdout, /Before:/);
  console.log(
    "Storage cleanup checks passed: audit, merge evidence, active/idle ownership, fail-closed guards, races, caches, lock and task interface.",
  );
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
