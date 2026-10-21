# RFC Index skeleton

Use this when a team has no RFC Index yet. Create it as a team-level Linear
document titled `RFC Index`, replace `<Team>`, and paste the content below (no
leading `#` title; Linear shows the title separately). Rows go newest first.

---

```markdown
Every <Team> engineering RFC (Request for Comments), newest first. An RFC is a design proposal shared for comments before we build. Each one lives as a document in the Linear project it concerns, or on the team; this page is the table of contents.

| # | RFC | Status | Decider | Date | Project | Decision issue |
| -- | -- | -- | -- | -- | -- | -- |

## How this works

* **Numbering:** <Team> RFCs are numbered in their own series (`RFC-001`, `RFC-002`, ...), separate from other teams' indexes, and the number goes in the document title. Numbers are never reused.
* **Status:** `Draft` -> `In Review` -> `Accepted` | `Rejected` | `Superseded by RFC-xxx`. Update the row here whenever an RFC's status changes.
* **Where an RFC lives:** as a document in its Linear project or on the team, with a decision issue assigned to the decider once it is In Review.
* **After acceptance:** the decision is recorded as an ADR in the repo it governs, and the RFC links to it.
```

---

## A row

```markdown
| RFC-001 | [<title>](<document url>) | Draft | — | 2026-01-31 | <project, issue or "team doc"> | — |
```

Fill `Decider` and `Decision issue` when the RFC moves to In Review.
