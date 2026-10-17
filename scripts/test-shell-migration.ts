#!/usr/bin/env bun
// Isolated contract checks. No deployed dotfiles, upgrades, or remote writes.
import assert from "node:assert/strict";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  realpathSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { createCipheriv, pbkdf2Sync } from "node:crypto";
import { Database } from "bun:sqlite";

const source = resolve(import.meta.dir, "..");
const home = realpathSync(mkdtempSync(join(tmpdir(), "shell-migration-")));
const bin = join(home, "bin");
mkdirSync(bin);
const env = {
  HOME: home,
  XDG_CONFIG_HOME: join(home, ".config"),
  PATH: `${bin}:/usr/bin:/bin`,
  HERDR_PANE_ID: "",
  CLAUDE_CONFIG_DIR: join(home, ".config/claude"),
};
function run(args: string[], cwd = home, extra: Record<string, string> = {}) {
  return Bun.spawnSync(args, {
    cwd,
    env: { ...env, ...extra },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
}
function good(args: string[], cwd = home, extra: Record<string, string> = {}) {
  const result = run(args, cwd, extra);
  assert.equal(result.exitCode, 0, result.stderr.toString());
  return result.stdout.toString().trim();
}
function stub(name: string, body: string) {
  const path = join(bin, name);
  writeFileSync(path, `#!/bin/bash\n${body}\n`);
  chmodSync(path, 0o755);
}
const script = (name: string) => join(source, "dot_local/bin/executable_" + name);
try {
  for (const os of ["darwin", "linux"]) {
    const profile = good(
      [
        "chezmoi",
        "--source",
        source,
        "execute-template",
        "--override-data",
        JSON.stringify({ chezmoi: { os, hostname: os === "linux" ? "box" : "mac" } }),
        "--file",
        join(source, "dot_profile.tmpl"),
      ],
      home,
      { PATH: process.env.PATH! },
    );
    writeFileSync(join(home, ".profile"), profile);
    for (const shell of ["/bin/bash", "/bin/zsh"]) {
      const output = good([
        shell,
        "-c",
        '. "$HOME/.profile"; . "$HOME/.profile"; printf "%s\\n" "$PATH" "$PI_CODING_AGENT_DIR" "$HOMEBREW_PREFIX"',
      ]);
      const [path, pi, brew] = output.split("\n");
      assert.equal(path!.split(":")[0], join(home, ".local/bin"));
      assert.equal(new Set(path!.split(":")).size, path!.split(":").length);
      assert.equal(pi, join(home, ".config/pi"));
      assert.equal(brew, os === "darwin" ? "/opt/homebrew" : "/home/linuxbrew/.linuxbrew");
    }
  }
  assert.equal(
    good([
      "/bin/bash",
      "-c",
      '. "$1"; printf "%s" "$PI_CODING_AGENT_DIR"',
      "_",
      join(source, "dot_bashrc"),
    ]),
    join(home, ".config/pi"),
  );
  const shared = join(source, "dot_config/shell/interactive.sh");
  const chosen = join(home, "chosen directory");
  mkdirSync(chosen);
  stub(
    "yazi",
    'while (($#)); do if [[ $1 == --cwd-file ]]; then printf "%s" "$CHOSEN" > "$2"; break; fi; shift; done; exit 7',
  );
  stub("chezmoi", '[[ $1 == source-path ]] || exit 99; printf "%s\\n" "$CHOSEN"');
  stub("bun", 'printf "external bun:%s\\n" "$*"');
  stub("amp", '[[ $AMP_REMOTE_CONTROL_TERMINAL == 1 && $1 == "two words" ]] || exit 98; exit 9');
  for (const shell of ["/bin/bash", "/bin/zsh"]) {
    assert.equal(
      good(
        [shell, "-c", '. "$1"; yazi; result=$?; printf "%s:%s" "$result" "$PWD"', "_", shared],
        home,
        { CHOSEN: chosen },
      ),
      `7:${chosen}`,
    );
    assert.equal(
      good([shell, "-c", '. "$1"; chezmoi cd; printf "%s" "$PWD"', "_", shared], home, {
        CHOSEN: chosen,
      }),
      chosen,
    );
    assert.equal(run([shell, "-c", '. "$1"; amp "two words"', "_", shared]).exitCode, 9);
    assert.equal(run([shell, "-c", '. "$1"; bun add --global something', "_", shared]).exitCode, 1);
    assert.equal(
      good([shell, "-c", '. "$1"; bun update --global --latest', "_", shared]),
      "external bun:update --global --latest",
    );
    assert.equal(
      good([shell, "-c", "false; printf semicolon; false && printf wrong; true"]),
      "semicolon",
    );
  }

  stub(
    "herdr",
    `
state="$HOME/$1-label"
if [[ $2 == rename ]]; then printf '%s' "$4" > "$state"
else
  value=$(cat "$state")
  if [[ $1 == pane ]]; then printf '{"result":{"pane":{"label":"%s","tab_id":"tab"}}}' "$value"
  else printf '{"result":{"tab":{"label":"%s","pane_count":1}}}' "$value"; fi
fi`,
  );
  // Nested temporary labels restore both owners and preserve the command's failure.
  for (const shell of ["/bin/bash", "/bin/zsh"]) {
    writeFileSync(join(home, "pane-label"), "original pane");
    writeFileSync(join(home, "tab-label"), "original tab");
    const result = run(
      [shell, "-c", '. "$1"; herdr-wrap outer herdr-wrap inner false', "_", shared],
      home,
      {
        HERDR_PANE_ID: "pane",
        PATH: `${bin}:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/bin:/bin`,
      },
    );
    assert.equal(result.exitCode, 1, `${shell}: ${result.stderr.toString()}`);
    assert.equal(readFileSync(join(home, "pane-label"), "utf8"), "original pane");
    assert.equal(readFileSync(join(home, "tab-label"), "utf8"), "original tab");
  }

  // Ordinary gh must forward every argument and failure, even on weekends.
  stub("gh", 'printf "%s\\n" "$@"; exit 23');
  const forwarded = run([process.execPath, script("gh"), "pr", "create", "--title", "two words"]);
  assert.equal(forwarded.exitCode, 23);
  assert.equal(forwarded.stdout.toString(), "pr\ncreate\n--title\ntwo words\n");
  // Cookie port uses synthetic input, never the user's keychain or cookies.
  const cookiePath = join(home, "Library/Application Support/net.imput.helium/Profile 1");
  mkdirSync(cookiePath, { recursive: true });
  const db = new Database(join(cookiePath, "Cookies"));
  db.run(
    "create table cookies (host_key text, name text, last_update_utc integer, encrypted_value blob)",
  );
  const cipher = createCipheriv(
    "aes-128-cbc",
    pbkdf2Sync("test-key", "saltysalt", 1003, 16, "sha1"),
    Buffer.alloc(16, 32),
  );
  const encrypted = Buffer.concat([
    Buffer.from("v10"),
    cipher.update(Buffer.concat([Buffer.alloc(32), Buffer.from("fake-session")])),
    cipher.final(),
  ]);
  db.run("insert into cookies values (?, ?, ?, ?)", ["github.com", "user_session", 1, encrypted]);
  db.close();
  stub("security", "printf test-key");
  assert.equal(good([process.execPath, script("gh"), "image", "extract-token"]), "fake-session");

  mkdirSync(env.CLAUDE_CONFIG_DIR, { recursive: true });
  const config = join(env.CLAUDE_CONFIG_DIR, ".claude.json");
  writeFileSync(
    config,
    JSON.stringify({
      extra: "keep",
      projects: {
        [home]: {
          mcpServers: { fff: {}, unknown: {} },
          disabledMcpServers: ["fff", "keep-disabled"],
        },
      },
    }),
  );
  good([process.execPath, script("claude-policy")]);
  const updated = JSON.parse(readFileSync(config, "utf8"));
  assert.equal(updated.extra, "keep");
  assert(updated.projects[home].disabledMcpServers.includes("unknown"));
  assert(updated.projects[home].disabledMcpServers.includes("keep-disabled"));
  assert(!updated.projects[home].disabledMcpServers.includes("fff"));
  assert.equal(updated.projects[home].hasTrustDialogAccepted, undefined);
  assert.equal(statSync(config).mode & 0o777, 0o600);
  const repo = join(home, "projects/work/repo space");
  mkdirSync(repo, { recursive: true });
  good(["git", "init", "--quiet", repo]);
  const before = readFileSync(config, "utf8");
  assert.equal(run([process.execPath, script("claude-policy"), "--trust"], repo).exitCode, 1);
  assert.equal(readFileSync(config, "utf8"), before);
  assert(!existsSync(config + ".lock"));
  mkdirSync(config + ".lock");
  assert.equal(run([process.execPath, script("claude-policy")]).exitCode, 1);
  assert(existsSync(config + ".lock"));

  // Updater keeps going after failure and reports it; no real upgrade commands on PATH.
  stub("uv", "exit 17");
  stub("bun", 'printf "reached bun\\n"');
  const update = run(["/bin/bash", script("updater"), "start"]);
  assert.equal(update.exitCode, 1);
  assert(update.stdout.toString().includes("reached bun"));
  console.log(
    "ok: environment, Bash/Zsh wrappers, cwd/status, gh passthrough/cookie, Claude policy/trust/lock, updater failure",
  );
} finally {
  rmSync(home, { recursive: true, force: true });
}
