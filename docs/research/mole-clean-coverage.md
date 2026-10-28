# Mole `mo clean` coverage for updater cleanup

## Scope

The installed `mo --version` reports Mole 1.64.0. The official `V1.64.0` tag resolves to commit `8eb31131b57e63419b97cab3500b906538eb341a`; its `mole` entrypoint sets `VERSION="1.64.0"` [S1]. The README requires macOS 12 or newer, so Linux is outside the documented platform support [S2].

`mo clean` deletes known-safe caches, logs, temporary files, developer caches, and leftovers from uninstalled apps. It permanently deletes selected items and empties `~/.Trash` by default; a whitelist can protect items, and volume Trash is excluded [S3, S4]. The normal run also scans large-file and project-artifact candidates, but these are report/hint categories. `mo purge` is the separate project-artifact cleanup command [S5]. Deep system cleanup is off by default [S6].

Its default sections include user essentials, app caches, browsers, cloud/office, developer tools, apps/utilities, virtualization, Application Support logs, app leftovers, Apple Silicon caches, cached device firmware, and failed Time Machine backups [S5].

## Updater overlap

Updater source: `dot_config/mise/tasks/updater/executable_clean:24-62`. Mise cache clear, pnpm, npm, uv, and Go cache cleaning now run only when Mole is unavailable. `mise prune` remains separate because Mole does not remove unused installed versions.

| Updater action                               | Mole 1.64.0 `mo clean` coverage                                                                                                                                                                                                               |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mise cache clear`                           | Covered, including dry-run. `mise prune` is not called, so unused installed versions remain separate package/version state. [S7]                                                                                                              |
| `pnpm store prune`                           | Covered conditionally. Mole prunes detected stores; dry-run reports the cache. It skips for an active pnpm process, missing/unusable store, or whitelist. [S8]                                                                                |
| npm cache clean                              | Covered. Mole dry-run reports it; a real run uses `npm cache clean --force` and also clears residual cache/log directories. [S9]                                                                                                              |
| bun cache                                    | Covered by Mole, though not listed in the updater. Dry-run reports it; a real run uses `bun pm cache rm` with a path-cleanup fallback. [S9]                                                                                                   |
| `uv cache clean`                             | Same cache family, different operation: Mole dry-run reports uv; the real run calls `uv cache prune`. Do not count this as the exact updater command. [S10]                                                                                   |
| Go build and module caches                   | **Covered:** Mole calls `go clean -cache` and `go clean -modcache`; dry-run adds Go's `-n` flag. This corrects the claim that Go cache cleanup is outside Mole's coverage. [S11]                                                              |
| Homebrew cleanup                             | Partial. Mole clears Homebrew downloads and stale service logs, and calls `brew cleanup --prune=30` at most once per seven days; it does not pass `--prune-prefix` or `--prune=all`. It only previews `brew autoremove --dry-run`. [S12]      |
| Docker container/network/image/builder prune | Not covered. Mole leaves daemon-managed data for review. It only removes local files under `~/.docker/buildx/cache`. [S13]                                                                                                                    |
| Linux Trash and user journal                 | Not covered. Mole's Trash target is macOS `~/.Trash`; its documented platform is macOS, and it has no Linux journal-cleanup operation. Keep the updater's Linux Trash and `journalctl --user --vacuum-size=200M` steps separate. [S2, S4, S5] |

Mole's cache categories depend on installed tools, whitelist settings, and process-safety checks. Its 1.64.0 release notes also say cleanup rechecks active apps/projects and keeps dependencies when recoverability is uncertain [S8, S14].

## Sources

- [S1] [`mole`, `VERSION`](https://github.com/tw93/Mole/blob/V1.64.0/mole#L115); [tagged source commit](https://github.com/tw93/Mole/commit/8eb31131b57e63419b97cab3500b906538eb341a).
- [S2] [README, Quick Start](https://github.com/tw93/Mole/blob/V1.64.0/README.md#L30-L38).
- [S3] [README, Safety and Clean](https://github.com/tw93/Mole/blob/V1.64.0/README.md#L148-L165).
- [S4] [`lib/clean/user.sh`, `clean_trash`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/user.sh#L40-L59).
- [S5] [`bin/clean.sh`, `run_clean_sections`](https://github.com/tw93/Mole/blob/V1.64.0/bin/clean.sh#L1767-L1859); [`user.sh`, report-only large-file scan](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/user.sh#L3244-L3245); [`hints.sh`, project-artifact hint](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/hints.sh#L398-L467); [README commands](https://github.com/tw93/Mole/blob/V1.64.0/README.md#L60-L70).
- [S6] [`bin/clean.sh`, `SYSTEM_CLEAN=false`](https://github.com/tw93/Mole/blob/V1.64.0/bin/clean.sh#L31-L38).
- [S7] [`lib/clean/dev.sh`, `get_mise_cache_path` and `clean_dev_mise`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L1124-L1164).
- [S8] [`dev.sh`, pnpm process/store discovery and `clean_pnpm_stores`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L340-L494); [`clean_developer_tools`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L5900-L5918).
- [S9] [`dev.sh`, `clean_tool_cache`, `clean_dev_npm`, pnpm and bun cache steps](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L12-L73), [#L496-L618](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L496-L618).
- [S10] [`dev.sh`, `clean_uv_cache` and `clean_dev_python`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L98-L111), [#L844-L878](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L844-L878).
- [S11] [`dev.sh`, Go cache command boundary](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L921-L970); [`clean_dev_go`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L1086-L1122).
- [S12] [`brew.sh`, `clean_homebrew` and autoremove preview](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/brew.sh#L294-L414), [`clean_homebrew_service_logs`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/brew.sh#L584-L650); [`dev.sh`, Homebrew downloads and service-log cleanup calls](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L5938-L5950).
- [S13] [`dev.sh`, `clean_dev_docker`](https://github.com/tw93/Mole/blob/V1.64.0/lib/clean/dev.sh#L1365-L1404).
- [S14] [V1.64.0 release notes](https://github.com/tw93/Mole/releases/tag/V1.64.0).
