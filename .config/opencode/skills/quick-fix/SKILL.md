---
name: quick-fix
description: Retroactively create a Jira bug ticket in AGP, jj bookmark, and push for a fix already in the working copy. Triggered by "quick fix", "quick bug", "log a bug", "create bug ticket", or when James has already made a change and needs to formalize it with a ticket and bookmark.
---

# Quick Fix

Create Jira ticket, jj bookmark, describe, push to GitLab.

## Workflow

### 1. Analyze the Fix

```bash
jj diff
jj st
```

Determine from the diff and conversation:

- **Summary**: Concise description (50-80 chars)
- **Description**: What was broken, root cause, what changed, file:line references
- **Work Type**: `Sustaining` for bug fixes, `New` for new features

### 2. Create Jira Ticket

Assignee is resolved from the `instructions` text. All other fields are resolved from `params`.

Project MUST be `"MCP"` (Zapier display name). Passing `"AGP"` (Jira key) will fail.

```
zapier-mcp_execute_write_action({
  app: "jira",
  action: "create_issue",
  instructions: "Create a Bug in project MCP. Assignee: James Baldwin.",
  output: "Return the issue key (e.g. AGP-1234) and the issue URL",
  params: {
    project: "MCP",
    issuetype: "Bug",
    "string::summary": "[SUMMARY]",
    "string::description": "[DESCRIPTION]",
    "string::customfield_10346": "[WORK_TYPE]"
  }
})
```

**Validation**: If the returned key does NOT start with `AGP-`, STOP. Tell James the integration put it in the wrong project. Provide the summary and description for manual creation.

### 3. Bookmark, Describe, Push

**Bookmark:** all lowercase, kebab-case, max 50 chars.

**Commit message:** all lowercase, no ticket ID, max 50 chars.

```bash
jj bookmark create agp-NNNN-short-description
jj describe -m 'lowercase short description, no ticket id'
jj git push --bookmark agp-NNNN-short-description
```

### 4. Report

```
Created AGP-XXXX: [summary]
  Jira:     https://zapierorg.atlassian.net/browse/AGP-XXXX
  Bookmark: [bookmark-name]
  Pushed:   yes

  ⚠ Set manually: sprint, parent epic

Ready for MR — say "create MR" when you want to open it.
```

## Zapier Jira Field Support

| Field       | create_issue | How                          |
| ----------- | ------------ | ---------------------------- |
| Project     | ✅           | `project: "MCP"`             |
| Issue Type  | ✅           | `issuetype: "Bug"`           |
| Assignee    | ✅           | Via `instructions` text      |
| Summary     | ✅           | `string::summary`            |
| Description | ✅           | `string::description`        |
| Work Type   | ✅           | `string::customfield_10346`  |
| Sprint      | ❌           | Resolver ignores; set manual |
| Parent/Epic | ❌           | Resolver ignores; set manual |
