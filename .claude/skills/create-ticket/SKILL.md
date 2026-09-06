---
name: create-ticket
description: Create a Jira ticket in the MCP project (AGP). Supports any issue type (defaults to Bug or Story; elicits feedback if unclear), picks an appropriate epic with a recommendation, and asks whether to assign James. Triggered by "create a ticket", "file a ticket", "spin off a ticket", "open a Jira ticket", "make a ticket". This skill is also the source of truth for all Jira mechanics and is delegated to by the quick-fix skill.
---

# Create Ticket

Create a Jira ticket in the MCP project (Jira key `AGP`), link it to an epic, and
optionally assign James. This is standalone work — it does NOT touch the working
copy or git. For formalizing a change you already made (diff → ticket → push), use
the `quick-fix` skill instead (it delegates the Jira parts to this skill).

**All Jira IDs, field keys, gotchas, and JQL live in
[`jira-reference.md`](./jira-reference.md). Read it before calling any Jira
action.**

## Workflow

### 1. Gather Ticket Details

From the conversation, determine:

- **Summary**: Concise title (50–80 chars)
- **Description**: What the ticket is about; include context, links, file:line
  refs where relevant
- **Issue Type**: See below
- **Work Type**: `Sustaining` (`10586`) for fixes/maintenance, `New` (`10585`)
  for new features/work

**Issue type selection:**

- Default to **Bug** for something broken, **Story** for new work or a feature.
- If the right type is genuinely unclear from the request, **elicit James's
  choice** (offer Bug / Story plus any obvious alternative like Spike or Design
  Task). Do not silently guess when ambiguous.
- See `jira-reference.md` for the full issue-type ID table.

### 2. Create the Ticket

Use the numeric IDs from `jira-reference.md` (the enum resolver is broken — never
pass label strings or the text "MCP"). Bug example:

```
zapier-mcp_execute_zapier_write_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "create_issue",
  instructions: "Create a Bug in project 11589. Assignee: James Baldwin.",
  output: "Return the issue key (e.g. AGP-1234) and the issue URL",
  params: {
    project: "11589",
    issuetype: "10004",
    "string::summary": "[SUMMARY]",
    "string::description": "[DESCRIPTION]",
    "option::customfield_10346": "10586"
  }
})
```

For other issue types, swap `issuetype` for the right ID (e.g. Story `10001`) and
adjust the `instructions` text and Work Type to match.

**Validation**: If the returned key does NOT start with `AGP-`, STOP. The
integration filed it in the wrong project. Give James the summary and description
for manual creation.

### 3. Set Epic (recommend + elicit)

Fetch the open AGP epics, pick the best-fit parent, and **present your
recommendation plus a couple of alternatives and a "no epic" option** — never
assign an epic silently.

```
zapier-mcp_execute_zapier_read_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "issue_jql",
  params: {
    jql: "project = AGP AND issuetype = Epic AND statusCategory != Done ORDER BY updated DESC",
    fields: "summary,status,updated"
  }
})
```

Common fits: `AGP-690 Code & Flag Cleanup` (style/cleanup/tech-debt),
`AGP-1684 Test Infrastructure`, `AGP-1634 Production Stability & Scalability`.

### 4. Ask About Assignment

**Ask James whether to assign the ticket to him.** Default suggestion is yes.

### 5. Apply Epic + Assignee

Apply the chosen epic and assignment via `update_issue`. Parent uses the epic KEY;
assignee uses James's account ID (in `jira-reference.md`).

```
zapier-mcp_execute_zapier_write_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "update_issue",
  params: {
    issueKey: "AGP-NNNN",
    "issuelink::parent": "AGP-690",
    "user::assignee": "712020:b89b36ad-2ce4-4fca-ab2b-4dc06a0b510c",
    "option::customfield_10346": "10586"
  }
})
```

**WARNING:** `update_issue` silently resets Work Type to `New` (`10585`) unless you
re-send it. ALWAYS include `option::customfield_10346` in the update, then verify
`fields.customfield_10346.value` in the response is correct. If it flipped,
re-send the update with just the Work Type. (Full details in `jira-reference.md`.)

### 6. Report

```
Created AGP-XXXX: [summary]
  Jira:     https://zapierorg.atlassian.net/browse/AGP-XXXX
  Type:     [issue type]
  Epic:     AGP-NNN [epic summary] (or none)
  Assignee: James Baldwin (or unassigned)

  ⚠ Set manually: sprint
```
