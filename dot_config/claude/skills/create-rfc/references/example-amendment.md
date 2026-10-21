# Worked example: recording review outcomes

Open this when an RFC's review has produced answers or scope changes and you
are about to amend it or mark it Accepted.

## 1. Happy path: Amendment A at sign-off

Review settled an open question in a comment thread and narrowed phase 1.
Insert above section 1 with `save_document` (`id` + `patch`, `insert_before`
`## 1. Context & Background`), so existing comment threads stay anchored:

```markdown
## 0. Amendment A (2026-10-08): supersedes conflicting text below

Recorded at signoff. Decided in the §8 question 1 comment thread (decider on 2026-10-06, author on 2026-10-07).

1. **§8 question 1 is option (c).** The third caller keeps calling the backend directly in phase 1. This supersedes:
   * §2 "Cut over all three callers": phase 1 cuts over two callers only;
   * §6 task 11 and its rows in §6.1;
   * the "keep the VM on 24/7" row in §3.8.
2. **§8 question 3 is the existing database.** The always-on requirement only applied to option 1(b).
3. **§8 questions 2 and 4 are deferred.** Neither blocks phase 1.
4. **Task changes:** phase 1 drops task 11 (about 2 days) and becomes about 16–17 engineer-days.
```

Then mark the questions in §8 so the trail survives, and point at the amendment:

```markdown
1. **Which host serves the third caller?** ... *Owner:* @decider. By: 2026-10-13.

   **Resolved (2026-10-08):** option (c) for phase 1. See Amendment A.
2. **Which job-queue server for phase 2?** ... Before phase 2. **Deferred (2026-10-08):** doesn't block phase 1.
```

Annotate superseded lines in place rather than deleting them, for example
`11. **Third-caller cutover** (deferred by Amendment A, not part of phase 1), ...`.

## 2. Robust variant: a second round of changes

A later review changes something Amendment A already decided. Add
`## 0. Amendment B (<date>)` **above** A, and say which item of A it overrides
(`Supersedes Amendment A item 3`). Never edit A in place: reviewers' comments
are anchored to its text.

## 3. Anti-pattern and fix

**Anti-pattern:** the decider answers an open question in a comment ("I think
option (c) is preferable"), the author replies "okay", the thread is resolved,
and the RFC is marked Accepted. The text still says the question is open and
still lists the work option (c) removed. Anyone reading the RFC later, or
creating issues from §6, follows the wrong plan.

**Fix:** before marking Accepted, write every comment answer into the RFC
(Amendment + §8 `Resolved`/`Deferred`), annotate superseded scope, and only then
update the status in the header, the RFC Index row and the decision issue.
