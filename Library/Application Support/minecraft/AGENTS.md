# Minecraft Java on this Mac

This directory is the Minecraft Java data root. Check the actual files here before assuming the game, profile, or mods are unchanged.

## Paths and safety

- Worlds: `saves/`
- Mods: `mods/`
- Current game log: `logs/latest.log`
- Launcher profiles: `versions/`

Treat `saves/` as user data. Never delete, overwrite, migrate, or edit world data without explicit permission. Back up a world before opening it in a newer Minecraft version.

## Java and Fabric

- The Minecraft Launcher selects a runtime for each profile. Inspect the selected profile and its version metadata when diagnosing Java compatibility; do not assume it uses the shell's `JAVA_HOME`.
- Check `JAVA_HOME` in a fresh configured shell when diagnosing Java tools. Existing shells may retain an earlier value.
- Inspect an installer executable or its package documentation before assuming it supports CLI flags; some installers launch a GUI.

## Adding or removing mods

1. Inspect `mods/` first. Identify installed mod IDs by reading `fabric.mod.json` inside each JAR; filenames alone can miss duplicates.
2. Match every download to the exact Minecraft version and Fabric loader in use. Prefer the newest stable release. Use Modrinth's project version API or project page, not an unrelated version or loader.
3. Follow required dependencies recursively. Skip optional dependencies unless the user asks for them or an installed mod needs them. Tell the user which dependency JARs you add.
4. Download the primary JAR from Modrinth and verify its SHA-512 against the API response before placing it in `mods/`. Refuse to overwrite existing files. Do not install source JARs.
5. Verify the archive and its `fabric.mod.json`. A file on disk does not prove that Minecraft loaded the mod. Mods load at startup; after the user relaunches, inspect the fresh `logs/latest.log` for Fabric and the expected mod IDs. If they are in-game, explain that a restart is required; do not restart without their request.

## Version upgrades

Inspect the installed profile, game version, loader, and mod IDs for each request. Do not upgrade Minecraft or mods unless the user asks. Before a requested upgrade, verify every installed mod and required dependency has a stable build for the target game version and loader. Use a separate launcher game directory for the new setup so the current profile, mods, and worlds stay intact. If any required mod is unavailable, report that and leave the working setup unchanged.

## Debug screen and graphics

Check the installed game's controls and official release notes before giving version-specific instructions. Prefer built-in debug options when they show the requested information. After changing a graphics API setting, restart the game and inspect the fresh `logs/latest.log` to confirm which backend is active. Explain the available fallback if rendering fails.
