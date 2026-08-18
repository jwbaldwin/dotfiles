---
name: create-ticket
description: Create a Jira ticket in the MCP project (key MCP). Supports any issue type (defaults to Bug or Story; elicits feedback if unclear), picks an appropriate epic with a recommendation, and asks whether to assign James. Triggered by "create a ticket", "file a ticket", "spin off a ticket", "open a Jira ticket", "make a ticket". This skill is also the source of truth for all Jira mechanics and is delegated to by the quick-fix skill.
---

# Create Ticket

Create a Jira ticket in the MCP project (Jira key `MCP`), link it to an epic, and
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

Use the numeric IDs from `jira-reference.md`. The Jira integration may expose
either generic Zapier execution tools or direct Jira tools.

With generic Zapier execution tools, use this Bug pattern:

```
zapier-mcp_execute_zapier_write_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "create_issue",
  instructions: "Create a Bug in project 11589. Assignee: James Baldwin.",
  output: "Return the issue key (e.g. MCP-1234) and the issue URL",
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

With the direct Jira surface from `$ZAPIER_MCP_URL`, use
`jira_software_cloud_create_issue`. First call `get_dynamic_properties_schema`
with project `11589` and the numeric issue type, then pass summary, description,
Work Type, parent, and assignee through the returned `dynamic_properties` keys.
Use `jira_software_cloud_find_issues_via_jql` for searches and
`jira_software_cloud_update_issue` for later changes. Resolve dynamic enums when
the tool schema requires it; do not guess their values.

**Validation**: If the returned key does NOT start with `MCP-`, STOP. The
integration filed it in the wrong project. Give James the summary and description
for manual creation.

### 3. Set Epic (recommend + elicit)

Fetch the open MCP epics, pick the best-fit parent, and **present your
recommendation plus a couple of alternatives and a "no epic" option** — never
assign an epic silently.

```
zapier-mcp_execute_zapier_read_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "issue_jql",
  params: {
    jql: "project = MCP AND issuetype = Epic AND statusCategory != Done ORDER BY updated DESC",
    fields: "summary,status,updated"
  }
})
```

Common current fits: `MCP-2289 Tech Debt`, `MCP-2288 Bugs`, and
`MCP-2351 Workflows Agentic UX`. Query live open epics every time; do not assign
a completed epic merely because an older example names it.

For an autonomous or scheduled run, follow any explicit epic and assignee defaults
in the run prompt without pausing. If the prompt authorizes choosing the best-fit
epic, choose from the live open-epic query and continue.

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
    issueKey: "MCP-NNNN",
    "issuelink::parent": "MCP-690",
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
Created MCP-XXXX: [summary]
  Jira:     https://zapierorg.atlassian.net/browse/MCP-XXXX
  Type:     [issue type]
  Epic:     MCP-NNN [epic summary] (or none)
  Assignee: James Baldwin (or unassigned)

  ⚠ Set manually: sprint
```
