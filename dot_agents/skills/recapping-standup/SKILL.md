---
name: recapping-standup
description: Reconstructs what the user did from their merged and open GitHub PRs and their Slack messages, then writes it as product-focused standup bullets. Use when the user asks to remember what they did yesterday, on a given day, or last week, or asks for help preparing a daily standup report.
---

# Recapping standup

The audience is the daily standup: teammates who know the products but not the code.

## 1. Resolve the window

- `yesterday` on a Monday means the previous Friday.
- `last week` means Monday through Friday of the previous calendar week.

Do not ask the user to confirm the dates.

## 2. Gather

```sh
gh search prs --author=@me --updated=<start>..<end> --json repository,title,url,state,updatedAt,isDraft --limit 100
```

Merged PRs are the record of what shipped. Open and draft PRs are work in progress, and their timestamps go stale — before reporting one as active work, check that it really moved inside the window.

For every PR returned, fetch its description before writing any bullet:

```sh
gh pr view <url> --json body
```

The title names the change; the body carries the defect, the symptom, and the reasoning a title can't hold. Write from the body, not the title.

Slack, via `slack_search_public_and_private`, `sort: timestamp`, `include_context: false`:

- one day: `from:me on:YYYY-MM-DD`
- a range: `from:me after:<day before start> before:<day after end>`

Slack carries the *why* behind each PR cluster, plus the work that produced no commit: debugging help, reviews, thread decisions.

## 3. Write

Group by workstream, not by repository and not by chronology. One bullet per workstream, ordered by how much the standup audience cares.

Each bullet names what changed for a person: a user, a teammate, an environment. Repository names, PR titles, PR numbers, framework names, and file paths stay out. Product names, dataset names, feature names, teammate names, and real numbers stay in — they are what makes a bullet specific.

Separate what shipped from what is still in review.

Drill down on every bullet. Name the actual defect and the symptom someone saw:

> Fixed a data import bug.

becomes

> Fixed an import bug where all images from the PAS9 labeling batch were silently skipped, because they lived in an archive storage location our import tool wasn't checking.

and

> Helped a teammate with an analytics query.

becomes

> Helped Novi figure out why her PAS9 dataset image counts didn't match up (20.5k uploaded vs. 16.5k in her report) — her query was only counting images that already had annotations attached, not the full upload set.

Output is a bold window heading and bullets. No preamble, no closing summary.
