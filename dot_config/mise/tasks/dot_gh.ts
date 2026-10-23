import { accessSync, constants, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { createDecipheriv, pbkdf2Sync } from "node:crypto";
import { Database } from "bun:sqlite";

try {
  const args = Bun.argv.slice(2);
  if (args.length === 2 && args[0] === "image" && args[1] === "extract-token") {
    const database = join(
      homedir(),
      "Library/Application Support/net.imput.helium/Profile 1/Cookies",
    );
    const key = Bun.spawnSync(
      ["security", "find-generic-password", "-a", "Helium", "-s", "Helium Storage Key", "-w"],
      { stdout: "pipe", stderr: "pipe" },
    );
    if (key.exitCode !== 0) throw new Error("Cannot read Helium Storage Key");
    const db = new Database(database, { readonly: true });
    let row: { encrypted_value: Uint8Array } | null;
    try {
      row = db
        .query<{ encrypted_value: Uint8Array }, []>(
          'select encrypted_value from cookies where host_key="github.com" and name="user_session" order by last_update_utc desc limit 1',
        )
        .get();
    } finally {
      db.close();
    }
    if (!row) throw new Error("Helium has no github.com user_session cookie");
    const derived = pbkdf2Sync(key.stdout.toString().trim(), "saltysalt", 1003, 16, "sha1");
    const decipher = createDecipheriv("aes-128-cbc", derived, Buffer.alloc(16, 0x20));
    const value = Buffer.concat([
      decipher.update(row.encrypted_value.subarray(3)),
      decipher.final(),
    ]).subarray(32);
    if (!value.length || !value.every((byte) => byte >= 32 && byte < 127))
      throw new Error("Invalid Helium cookie");
    console.error("Extracted session token from Helium main");
    console.log(value.toString());
  } else {
    const self = realpathSync(Bun.main);
    const realGh = (process.env.PATH || "")
      .split(":")
      .map((directory) => join(directory || ".", "gh"))
      .find((candidate) => {
        try {
          accessSync(candidate, constants.X_OK);
          return realpathSync(candidate) !== self;
        } catch {
          return false;
        }
      });
    if (!realGh) throw new Error("Cannot find the real gh executable");
    process.exitCode = Bun.spawnSync([realGh, ...args], {
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    }).exitCode;
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
}
