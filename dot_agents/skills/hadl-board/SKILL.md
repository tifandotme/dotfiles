---
name: hadl-board
description: Use when creating or updating cards on the Hadl Product Engineering Trello board. Covers card creation, description updates, checklists, labels, and member assignment. Trigger on "create a card", "add to Trello", "make a ticket", "update this card", "add a checklist", "log this as a task", or any request to track work on the board.
---

# Hadl Board

Manages cards on the **Product Engineering** Trello board.

## References

- **[references/board.md](references/board.md)** — board ID, list IDs, label IDs, member IDs. Load whenever you need IDs for API calls.
- **[references/template.md](references/template.md)** — naming convention, description template, checklist guidance, writing rules. Load when drafting or editing a card description.

## Workflow

1. **Understand the request** — clarify list, assignees, labels, due date, checklist items if not specified.

2. **If drafting or editing a description**: load `references/template.md`, `writing-clearly-and-concisely`, and `humanizer` before writing.

3. **Show a preview** and wait for confirmation before writing to Trello:

   ```
   📋 Card Preview
   Name: <name>
   List: <list>
   Labels: <labels>
   Assignees: <names>

   Description:
   <formatted description>

   Checklist (if any):
   - [x] done item
   - [ ] pending item
   ```

4. **Execute** via the Trello API (see commands below).

5. **Share the result** — output the card name and Trello URL.

## Defaults

- **List**: Backlog
- **Assignee**: Tifan, unless specified otherwise
- **Due date**: none
- **Checklist**: only if the task has clear sub-steps

## API Commands

> Always use `printf` to build multi-line descriptions. Double-quoted bash strings do not interpret `\n` as newlines — the description collapses into one paragraph.

```bash
# Build description
DESC=$(printf "## Context / Background\n\n- **Current Condition:** ...\n...")

# Create card
CARD=$(curl -s -X POST "https://api.trello.com/1/cards" \
  --data-urlencode "key=$TRELLO_API_KEY" \
  --data-urlencode "token=$TRELLO_TOKEN" \
  --data-urlencode "idList=<listId>" \
  --data-urlencode "name=<name>" \
  --data-urlencode "desc=$DESC" \
  --data-urlencode "idMembers=<memberId1>,<memberId2>")
CARD_ID=$(echo "$CARD" | jq -r '.id')
CARD_URL=$(echo "$CARD" | jq -r '.shortUrl')

# Update card (description, name, list, members)
curl -s -X PUT "https://api.trello.com/1/cards/<cardId>" \
  --data-urlencode "key=$TRELLO_API_KEY" \
  --data-urlencode "token=$TRELLO_TOKEN" \
  --data-urlencode "desc=$DESC" > /dev/null

# Add label (one per request)
curl -s -X POST "https://api.trello.com/1/cards/<cardId>/idLabels" \
  -G \
  --data-urlencode "key=$TRELLO_API_KEY" \
  --data-urlencode "token=$TRELLO_TOKEN" \
  --data-urlencode "value=<labelId>" > /dev/null

# Create checklist
CHECKLIST=$(curl -s -X POST "https://api.trello.com/1/checklists" \
  --data-urlencode "key=$TRELLO_API_KEY" \
  --data-urlencode "token=$TRELLO_TOKEN" \
  --data-urlencode "idCard=<cardId>" \
  --data-urlencode "name=Progress")
CHECKLIST_ID=$(echo "$CHECKLIST" | jq -r '.id')

# Add checklist item (checked=true for already-done items)
curl -s -X POST "https://api.trello.com/1/checklists/$CHECKLIST_ID/checkItems" \
  --data-urlencode "key=$TRELLO_API_KEY" \
  --data-urlencode "token=$TRELLO_TOKEN" \
  --data-urlencode "name=<item>" \
  --data-urlencode "checked=false" > /dev/null

# List checklist items (to find IDs for update/delete)
curl -s "https://api.trello.com/1/checklists/<checklistId>/checkItems?key=$TRELLO_API_KEY&token=$TRELLO_TOKEN" \
  | jq '.[] | {id, name, state}'

# Delete checklist item
curl -s -X DELETE "https://api.trello.com/1/cards/<cardId>/checkItem/<checkItemId>" \
  -G \
  --data-urlencode "key=$TRELLO_API_KEY" \
  --data-urlencode "token=$TRELLO_TOKEN" > /dev/null
```
