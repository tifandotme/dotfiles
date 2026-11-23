---
name: second-brain
description: "Reads, writes, moves, and organizes notes in Tifan's Obsidian vault (~/projects/personal/notes): Hadl work notes, personal notes, references, and clippings. Use for any task that touches these notes, including through the mcpvault MCP."
---

# Notes vault

Markdown syntax comes from the `obsidian-markdown` and `obsidian-bases` skills. Web pages and YouTube transcripts: `defuddle parse <url> --md`.

## Access

- Use the `mcpvault` MCP for note reads and writes when present; otherwise filesystem tools.
- Renaming a note with `move_note` or `mv` leaves links to the old name in other notes. After a rename, `rg` the vault for the old name and fix the links. Moving a note to another folder without renaming breaks nothing.

## Sync

Drive for desktop syncs the MacBook; `rclone bisync` runs on box 3 s after the last local edit (`notes-drive-watch.service`) and every minute (`notes-drive-sync.timer`), which also pulls MacBook edits. Edit a given note on one machine at a time, because bisync writes conflict copies. Before a bulk delete of over 50% of the files, stop the timer on box and run one manual bisync with `--max-delete 100` (a percentage).

## Layout

List folders with `list_directory`. What the names don't say:

- `hadl/archive/` holds Tifan's finished Hadl work. It stays frozen.
- `hadl/` is active Hadl work only.
- `attachments/hadl/` holds Hadl artifacts and diagrams.
- `Clippings/` receives web clips from the Obsidian Web Clipper.
- `reference/` also holds Tifan's dev workflow notes.

When you create, rename, or retire a top-level folder, update this section in the same change.

## Conventions

- Filenames are kebab-case, followed by a `# H1` title.
- Frontmatter holds `type:` (`Area`, `Person`, `Meeting`, `SOP`, `Research`, `Reference`, `Note`), existing `tags`, and `aliases:` for real alternate names.
- Relationships live in wikilinks and in Bases filtered by folder and `type`.
- Retire notes by moving them to `hadl/archive/` or setting `_archived: true`. Ask Tifan before deleting.
