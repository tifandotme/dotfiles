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

> **Always use Python for all Trello API calls.** Never use curl + bash for descriptions — backticks and other special characters in the description text are interpreted by the shell, causing silent corruption or command execution. Python has no interpolation issues.
>
> Use a `python3 - <<'PYEOF' ... PYEOF` heredoc so the script body is never touched by the shell.

```python
# Full example: create card, add label, create checklist with items
python3 - <<'PYEOF'
import os, urllib.request, urllib.parse, json

key = os.environ["TRELLO_API_KEY"]
token = os.environ["TRELLO_TOKEN"]

desc = """## Context / Background

- **Current Condition:** ...
- **What we want to achieve:** ..."""

# Create card
data = urllib.parse.urlencode({
    "key": key, "token": token,
    "idList": "<listId>",
    "name": "<name>",
    "desc": desc,
    "idMembers": "<memberId1>,<memberId2>",
}).encode()
req = urllib.request.Request("https://api.trello.com/1/cards", data=data, method="POST")
with urllib.request.urlopen(req) as r:
    card = json.loads(r.read())
card_id = card["id"]
print("CARD_ID=" + card_id)
print("CARD_URL=" + card["shortUrl"])

# Add label (one per request)
data = urllib.parse.urlencode({"key": key, "token": token, "value": "<labelId>"}).encode()
req = urllib.request.Request(f"https://api.trello.com/1/cards/{card_id}/idLabels", data=data, method="POST")
with urllib.request.urlopen(req): pass

# Create checklist
data = urllib.parse.urlencode({"key": key, "token": token, "idCard": card_id, "name": "Progress"}).encode()
req = urllib.request.Request("https://api.trello.com/1/checklists", data=data, method="POST")
with urllib.request.urlopen(req) as r:
    cl_id = json.loads(r.read())["id"]

# Add checklist items
items = [
    ("Already done item", True),
    ("Pending item", False),
]
for name, checked in items:
    data = urllib.parse.urlencode({
        "key": key, "token": token,
        "name": name,
        "checked": "true" if checked else "false",
    }).encode()
    req = urllib.request.Request(f"https://api.trello.com/1/checklists/{cl_id}/checkItems", data=data, method="POST")
    with urllib.request.urlopen(req): pass
PYEOF

# Update card (description, name, list, members)
python3 - <<'PYEOF'
import os, urllib.request, urllib.parse

key = os.environ["TRELLO_API_KEY"]
token = os.environ["TRELLO_TOKEN"]

data = urllib.parse.urlencode({"key": key, "token": token, "desc": "new desc"}).encode()
req = urllib.request.Request("https://api.trello.com/1/cards/<cardId>", data=data, method="PUT")
with urllib.request.urlopen(req): pass
PYEOF

# List checklist items (to find IDs for update/delete)
python3 - <<'PYEOF'
import os, urllib.request, urllib.parse, json

key = os.environ["TRELLO_API_KEY"]
token = os.environ["TRELLO_TOKEN"]
params = urllib.parse.urlencode({"key": key, "token": token})
with urllib.request.urlopen(f"https://api.trello.com/1/checklists/<checklistId>/checkItems?{params}") as r:
    for i in json.loads(r.read()):
        print(json.dumps({"id": i["id"], "name": i["name"], "state": i["state"]}))
PYEOF

# Delete checklist item
python3 - <<'PYEOF'
import os, urllib.request, urllib.parse

key = os.environ["TRELLO_API_KEY"]
token = os.environ["TRELLO_TOKEN"]
params = urllib.parse.urlencode({"key": key, "token": token})
req = urllib.request.Request(
    f"https://api.trello.com/1/cards/<cardId>/checkItem/<checkItemId>?{params}",
    method="DELETE"
)
with urllib.request.urlopen(req): pass
PYEOF
```
