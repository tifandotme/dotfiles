---
name: second-brain
description: "Reads, writes, moves, and organizes notes in Tifan's Obsidian vault (~/projects/personal/notes): Hadl work notes, personal notes, references, and clippings. Use for any task that touches these notes, including through the mcpvault MCP."
---

# Notes vault

First read `AGENTS.md` in the vault (`read_note`) for the layout and note conventions.

Markdown syntax comes from the `obsidian-markdown` and `obsidian-bases` skills. Web pages and YouTube transcripts: `defuddle parse <url> --md`.

## Access

- Use the `mcpvault` MCP for note reads and writes when present; otherwise filesystem tools.
- Renaming a note with `move_note` or `mv` leaves links to the old name in other notes. After a rename, `rg` the vault for the old name and fix the links. Moving a note to another folder without renaming breaks nothing.

## Sync

Drive for desktop syncs the MacBook; `rclone bisync` runs on box every 5 minutes (`notes-drive-sync.timer`). Edit a given note on one machine at a time, because bisync writes conflict copies. Before a bulk delete of over 50% of the files, stop the timer on box and run one manual bisync with `--max-delete 100` (a percentage).
