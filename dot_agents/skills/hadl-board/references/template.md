# Card Format

Canonical template (keep in sync): [Engineering Card Template](https://trello.com/c/W8ayvn21/97-engineering-card-template)

## Naming Convention

- Plain title for clear standalone tasks: `CVAT Database Access`
- Product prefix for product-specific work: `[AquaSense] Improve health result CSV export`
- Topic:subtopic for feature work: `Windmill: Annotation ops dashboard`

## Description Template

Adjust depth to the task. Use short bullets or `N/A` where a section does not apply.

```
## Context / Background

- **Current Condition:** [Describe the current state, limitation, or problem]
- **What we want to achieve:** [Describe the goal, expected outcome, or target state]

## Implementation Details

- **Architecture/Approach:** Briefly describe the intended technical approach.
- **Relevant Repos/Files:** `link to repo/files`
- **Infrastructure/Dependencies:** [e.g., Required database migrations, GCP/AWS service updates, Terraform changes]

## Definition of Done

- [Example: Code is peer-reviewed and merged.]
- [Example: Unit/Integration tests are written and passing]
- [Example: QA steps have been successfully verified.]
- [Specific acceptance criteria 1]
- [Specific acceptance criteria 2]
```

Note: use Trello's **Checklist** for action steps — do not add an action checklist section to the description.

## Checklist

Name it `Progress`. Align items with the Definition of Done where it makes sense. Pre-check items that are already done (`checked=true`).

## Writing

Before drafting or editing a description, load:
- `writing-clearly-and-concisely` — tight, active prose
- `humanizer` — strip AI patterns

`**Bold Label:**` prefixes in bullets are fine to keep for scannability. Humanizer applies to the prose within each bullet, not the labels themselves.
