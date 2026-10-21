# create-rfc: maintenance spec

Not loaded at runtime. Read this before changing the skill.

## Purpose

Write, publish, amend and close engineering RFCs as Linear documents, so a team
can disagree on paper before building. Covers the whole lifecycle: interview,
research, draft, self-review, publish (Draft or In Review), amendments, and
sign-off (Accepted, Rejected, Superseded).

## Scope

- **In:** RFCs and design proposals in Linear; RFC Index pages, one per team;
  decision issues; amendments; the sign-off check.
- **Out:** ADRs written directly (the `domain-modeling` skill), user-facing
  docs, PR descriptions.

## Files

| File | Role |
| -- | -- |
| `SKILL.md` | Runtime workflow (steps 1–6) |
| `references/template.md` | Source of truth for RFC structure and per-section guidance |
| `references/rfc-index.md` | Skeleton for a team's first RFC Index |
| `references/example-amendment.md` | Worked example: amendment, resolved/deferred questions, anti-pattern |

## Dependencies

- **Linear MCP tools** (`list_teams`, `list_projects`, `list_users`,
  `list_documents`, `get_document`, `save_document`, `save_issue`,
  `list_comments`). Fallback: the `linear-cli` skill
  (https://github.com/schpet/linear-cli/blob/main/skills/linear-cli/SKILL.md).
- **`domain-modeling` skill** for ADR bodies
  (https://github.com/mattpocock/skills/blob/main/skills/engineering/domain-modeling/SKILL.md).
- Optional: `npx @mermaid-js/mermaid-cli` to render diagrams before publishing.

## Behaviour contract

- Asks once, in one batch, before drafting; always asks where the RFC lives.
- Publishes only after the user confirms; Draft unless comments are wanted now.
- Never marks Accepted while the decider hasn't signed, comment answers aren't
  in the text, or threads are open; reports what's missing instead.
- Amends instead of rewriting reviewed text, so comment anchors survive.
- Updates status in three places: header, RFC Index row, decision issue.

## Known pitfalls (keep in SKILL.md)

- Mermaid: `;` in a label breaks the diagram.
- Linear: `@mention` inside bold/italic and inline code inside strikethrough
  render broken; the API can't resolve comment threads.
- `linear-cli` document updates replace whole content and can detach threads.

## Update when

- Linear's document or MCP behaviour changes (nesting, mentions, patching).
- The team changes its RFC status flow, index columns, or ADR home.
- A real RFC session hits a failure the skill didn't prevent: add it to
  "Known pitfalls" and the matching runtime step.

## Open items

- None. The skill is workspace-neutral; keep organisation names, issue
  prefixes and internal systems out of runtime files.
