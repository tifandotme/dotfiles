---
name: create-rfc
description: Write an engineering RFC (Request for Comments) for any team in a Linear workspace -- a design proposal that frames a decision, the options, and the trade-offs so teammates can comment before anything is built -- and publish it as a Linear document. Use whenever the user asks to write, draft, start, or structure an RFC, design doc, technical proposal, or "proposal for comments"; when they want to get the team's input on an architecture, platform, vendor, migration, schema, or licensing decision before committing; or when they say things like "tulis RFC", "bikin proposal", "we need to decide between X and Y, write it up for the team". Also use when revising an existing RFC after review (amendments) or turning an accepted RFC into an ADR. Prefer this over generic document or co-authoring skills whenever the document is a technical decision for team review. Not for ADRs written directly (use domain-modeling), client or sales proposals, user-facing docs, or PR descriptions.
---

# Writing an RFC

An RFC exists so people can disagree **on paper, before code**. It earns its keep
when a reviewer can read it once, understand what is being decided and why, and
push back on something specific. Everything below serves that: a decision a
reader can find, evidence they can check, alternatives they can believe were
weighed, and questions they know they are being asked.

The house template lives in this skill: `references/template.md` has the
skeleton with guidance per section. Read that file before drafting. It is the
source of truth for RFC structure; don't copy the shape of an older RFC instead.

## Workflow

### 1. Interview first

A draft written from a one-line prompt invents the context, and invented context
is the thing reviewers then spend their time correcting. So ask before writing,
but ask once, in one batch, and only what the conversation, repo, and Linear
cannot answer:

- **The decision:** what exactly is being decided, and what happens if nobody decides?
- **Why now:** the trigger (incident, client ask, cost, deadline).
- **Constraints:** budget, deadline, compliance or licensing, things already committed.
- **Options already on the table**, and any the user has ruled out and why.
- **Audience and decider:** who must sign off, who should comment, by when.
  Resolve each person to their Linear account (`list_users`, by name or email)
  instead of guessing from a GitHub handle. For commit authors, match the commit
  email to the Linear email; Git display names often differ from Linear names.
- **Where it lives in Linear -- always ask, never assume:** which **team** owns
  it, and where the document attaches: a **project** (shows in
  its Documents tab), an **issue**, the **team** itself (a team-level document),
  or somewhere else the user names. Offer the likely candidates you found
  (`list_teams`, `list_projects` for that team, related issues) rather than an
  open question. The team also decides which RFC Index and numbering the RFC
  uses (step 5), and where the decision issue goes.

Skip questions already answered. If the user wants speed, take what you have and
carry the gaps into Open Questions rather than guessing.

### 2. Research before drafting

An RFC is credible when it says "measured live: 10 companies, 72 users" rather
than "a small number of users". Ground claims the same way:

- Read the code and config the proposal touches (`origin/main`, not a stale local
  branch). Name files and the current behaviour.
- Read related design docs and ADRs in the repos the proposal touches (decision
  records live in places like `docs/adr/`, `docs/decisions/`, `decisions/`, or
  any `decision-*.md` / `ADR-*.md`) so the RFC neither contradicts nor repeats
  a decision already made. If it reverses one, say so and link it.
- Read the Linear issue/project and comments for requirements and prior debate.
- For vendor or platform comparisons, use current public pricing and docs, and
  date them -- prices drift and a reader needs to know how stale a number is.
- Measure what can be measured (row counts, request volumes, costs) and say how.

Use subagents for broad research so the drafting context stays clean.

### 3. Draft

Follow `references/template.md`. Scale it: a two-option vendor choice needs a
few pages, not 800 lines. Drop sections that would only say "N/A", except Goals/Non-Goals, Alternatives, and Open Questions, which every
RFC needs because they are what reviewers argue about.

Principles that make an RFC reviewable:

- **Lead with the decision.** A reader should know within the first screen what
  is proposed and what is being asked of them.
- **Non-goals are as important as goals.** They stop scope arguments in comments.
- **Alternatives must be real.** Give each rejected option its strongest case and
  the specific reason it lost. A strawman tells reviewers the decision was made
  first and justified after, and they stop trusting the rest.
- **Quantify.** Cost per month, latency, row counts, effort in days. Ranges are
  fine; vague adjectives are not.
- **Show sequencing.** For anything touching production: the order of steps,
  what runs during the gap between them, and how to roll back. Most real
  breakage comes from ordering (migrations applied by hand, config or script
  sync vs service deploy, infrastructure applies), not from design.
- **Open questions are questions.** Each names who should answer and, ideally,
  by when. A reviewer should know which ones are theirs.
- **Write for someone who wasn't in the room.** Define acronyms once; link
  rather than assume.

#### Diagrams

Add a diagram when the reader would otherwise have to build the picture in
their head from prose; skip it when a sentence does the job. Pick by what the
proposal changes:

| Proposal changes | Diagram | Shows |
| --- | --- | --- |
| New services, infra, platform or vendor | Architecture | components, where each runs, trust and network boundaries, who manages it |
| Data crossing systems (pipelines, sync, replication, inference paths) | Data flow | numbered steps from source to sink, formats, sync vs async, where data rests |
| Schema (new tables, relations, data moving between DBs) | ERD | entities, keys, cardinality; plus a column table per new or changed table |
| Multi-step interactions where order matters (auth, webhooks, deploy order) | Sequence | actors and the order of calls, including failure and retry paths |

Show **current and proposed** side by side when the change is the point
("today" vs "after"). Keep one idea per diagram; two small diagrams beat one
crowded one.

How to draw them (Linear renders Mermaid: a fenced code block starting with
```` ```mermaid ```` becomes a diagram, per https://linear.app/docs/editor):
- **Default: Mermaid.** `flowchart` for architecture, meaning where things run
  (use `subgraph` for projects, VPCs and trust boundaries). `sequenceDiagram`
  for data flow and any ordered interaction: services as vertical lifelines,
  numbered horizontal arrows for each step (`autonumber`), which reads better
  than a flowchart when the order of hops matters. `erDiagram` for schemas. It
  renders as a real diagram, stays text so reviewers can suggest edits, and
  diffs cleanly. Keep node labels short; put detail in the prose under the
  diagram.
- **Keep labels plain.** No `;` anywhere in a label or message (Mermaid reads it
  as a new statement and the diagram fails), no `->` or `{}` inside message
  text, and quote node labels that contain spaces or brackets. If `npx` is
  available, render each block before publishing:
  `npx -y -p @mermaid-js/mermaid-cli mmdc -i diagram.mmd -o diagram.png`.
- **Plain-text box diagrams** only when Mermaid can't express the layout well,
  or for a tiny inline sketch.
- **ERDs:** a Mermaid `erDiagram` for the relations plus a markdown table per
  table (column | type | null | key | notes). Reviewers comment on table rows far
  more precisely than on a picture.
- After publishing, re-read the document (`get_document`) and check each Mermaid
  block survived as a `mermaid` code block; if Linear stored it as plain code,
  tell the user rather than assuming it rendered.

### 4. Self-review before showing the user

Read the draft as a skeptical reviewer would and fix what fails:

- Can the decision and the ask be found in under a minute?
- Is every number sourced or marked as an estimate?
- Would the strongest advocate of each rejected alternative say it was represented fairly?
- Is there a rollback, and does the rollout order survive a step failing halfway?
- Are licensing, security, data residency, and cost addressed where relevant?
- Does anything contradict an existing ADR without saying so?

### 5. Publish to Linear (confirm first)

Show the user the title, where it will attach, and the draft (or a summary for a
long one), and publish only after they confirm -- a Linear document is visible to
the whole workspace.

Linear documents cannot nest, so RFCs are organised by a numbering scheme, a
home the user chose (step 1), and **one index page per team**:

- **The team's RFC Index:** a team-level document titled "RFC Index" on the
  owning team. Find it with `list_documents` (query `RFC Index`) and match its
  `team`; each team numbers its own RFCs (`RFC-001`, `RFC-002`, ...), so read
  that team's index (`get_document`) for the next number: its highest `RFC-NNN`
  plus one. Numbers are never reused.
- **No index on that team yet:** ask before creating one. Create it as a
  team-level document titled `RFC Index` with `save_document` (`team`), from
  the skeleton in `references/rfc-index.md`, then start at `RFC-001`.

Publish in this order with the Linear MCP tools (load them via ToolSearch if
deferred). If they aren't available, do the same steps through the `linear-cli`
skill (`linear document create/update`, `linear issue create`); if that skill
isn't installed locally, read it from
https://github.com/schpet/linear-cli/blob/main/skills/linear-cli/SKILL.md.
The CLI replaces a document's whole content on update, which can detach comment
threads, so prefer the MCP tools (`patch`) for edits to a published RFC.

1. **The RFC document** with `save_document`:
   - `title`: `RFC-NNN: <decision in a few words>`
   - parent: exactly what the user chose in step 1 -- `project`, `issue` or
     `team` (one parent only; Linear refuses two)
   - `content`: the markdown without a leading `# ` title line (Linear shows the
     title separately). Mention people as `@displayName`.
   - **Status:** `Draft` unless the user wants comments now. A Draft gets this
     document and its index row (step 4, with `—` for an unknown decider and for
     the decision issue) and skips steps 2–3. Moving a Draft to `In Review` later
     runs steps 2–3 and updates the index row.
2. **A decision issue** with `save_issue` on the owning team (and in the chosen
   project, if there is one; ask which project when the RFC sits on the team or
   an issue), assigned to the
   decider, due on the comment-by date: title `Decide on RFC-NNN: <title>`, body
   linking the document, listing what to decide and what happens on acceptance.
3. **Link back:** `save_document` with `id` and a `patch` adding a
   `| **Decision issue** | [TEAM-123](url) |` row to the RFC's header table.
4. **Index row:** `save_document` on the owning team's RFC Index with a `patch`
   inserting the new row at the top of the table (newest first). The `Project`
   column holds the project, issue or "team doc" the RFC is attached to.

Linear renders markdown tables, code blocks and Mermaid diagrams. It breaks two
things: an `@mention` inside bold or italic text, and inline code inside a
strikethrough. Keep mentions outside emphasis, and strike plain words only.
Give the user the document, issue and index URLs. Teams can pin the index on the team home page; that is a
manual click in Linear, so tell the user if it isn't pinned yet.

### 6. After review

- **Changes after review:** add an `Amendment` block at the top (date, what
  changed, which sections it supersedes) instead of silently rewriting history,
  in the format `references/template.md` gives under "Amendments" (worked
  example in `references/example-amendment.md`). Update with `save_document`
  using `id` and `patch` so comments stay anchored. Bump the status line.
- **Before marking Accepted, check** and report what's missing instead of
  accepting:
  1. The decider's row in the Signoff table is filled in.
  2. Every answer given in a comment is written into the RFC: the §8 question
     marked `Resolved` or `Deferred`, plus an Amendment if scope changed.
  3. No comment thread is still open (`list_comments` on the document). The API
     can't resolve threads, so ask the user or the commenter to resolve them.
  4. The document was updated after any reply that promised a change.
- **Accepted:** set Status to Accepted, then record the decision as an ADR in the
  repo it governs, following that repo's existing ADR convention. Use the
  `domain-modeling` skill for the ADR body; if it isn't installed locally, read it
  from https://github.com/mattpocock/skills/blob/main/skills/engineering/domain-modeling/SKILL.md.
  Link the ADR back to the RFC. The RFC keeps the reasoning; the
  ADR is the durable, short record of what was decided.
- **Rejected or superseded:** set the status and one line on why, so nobody
  re-proposes it without new information.

Status values: `Draft` -> `In Review` -> `Accepted` | `Rejected` | `Superseded by <link>`.
Whenever the status changes, update it in three places: the RFC header table,
the RFC Index row, and the decision issue (Done on accepted or rejected).
