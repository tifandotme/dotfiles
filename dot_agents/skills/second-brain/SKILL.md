---
name: second-brain
description: "Reads, writes, moves, and organizes notes in Tifan's Obsidian vault (~/projects/personal/notes): Hadl work notes, personal notes, references, and clippings. Use for any task that touches these notes, including through the mcpvault MCP."
---

# Notes vault

Markdown syntax comes from the `obsidian-markdown` and `obsidian-bases` skills. Web pages and YouTube transcripts: `defuddle parse <url> --md`.

## Access

- Use the `mcpvault` MCP for note reads and writes when present; otherwise filesystem tools.
- `move_note` and `mv` leave links to the old name intact. After a move or rename, `rg` the vault for the old name and fix the links.

## Sync

Drive for desktop syncs the MacBook; `rclone bisync` runs on box every 5 minutes (`notes-drive-sync.timer`). Edit a given note on one machine at a time, because bisync writes conflict copies. Before a bulk delete of over 50% of the files, stop the timer on box and run one manual bisync with `--max-delete 100` (a percentage).

## Layout

- `hadl/`: active Hadl work.
- `hadl/archive/`: Tifan's finished Hadl work (C1 data intake, annotation review, IAA RFC, Estu's SOP, role notes). It stays frozen.
- `personal/`: health, goals, life.
- `reference/`: evergreen how-tos and dev workflow.
- `Clippings/`: web clips from the Obsidian Web Clipper.
- `attachments/`: images and diagrams; Hadl artifacts under `attachments/hadl/`.

## Conventions

- Filenames are kebab-case, followed by a `# H1` title.
- Frontmatter holds `type:` (`Area`, `Person`, `Meeting`, `SOP`, `Research`, `Reference`, `Note`), existing `tags`, and `aliases:` for real alternate names.
- Relationships live in wikilinks and in Bases filtered by folder and `type`.
- Retire notes by moving them to `hadl/archive/` or setting `_archived: true`. Ask Tifan before deleting.
