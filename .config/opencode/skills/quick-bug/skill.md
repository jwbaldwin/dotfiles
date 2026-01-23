---
name: quick-bug
description: Quickly create a bug fix JIRA ticket in AGP (MCP), assigned to James Baldwin, in the current sprint, set to In Progress. Use when the user says "quick bug", "log a bug", "create bug ticket", or similar.
license: MIT
allowed-tools:
  - zapier-mcp_execute_write_action
  - zapier-mcp_execute_search_action
metadata:
  version: "1.0"
---

# Quick Bug

Rapidly create a bug fix JIRA ticket with sensible defaults for quick fixes discovered during development.

## When to Use This Skill

Activate this skill when:

- The user says "quick bug: [description]"
- The user says "log a bug for [issue]"
- The user says "create bug ticket for [problem]"
- The user describes a bug they just fixed and wants to document it

## Defaults (Always Applied)

- **Project:** AGP (MCP)
- **Issue Type:** Bug
- **Assignee:** James Baldwin
- **Status:** In Progress
- **Sprint:** Current active sprint

## Workflow

### 1. Parse Bug Details

Extract from the user's message:

- **Title/Summary:** A concise description of the bug (50-80 chars ideal)
- **Description:** Technical details including:
  - What was broken
  - Root cause (if known)
  - The fix applied
  - Where it was introduced (MR/commit if known)

### 2. Create the JIRA Ticket

Use the Zapier MCP tool:

```
zapier-mcp_execute_write_action({
  app: "jira",
  action: "create_issue",
  instructions: `Create a Bug issue with:
- Project: AGP (MCP)
- Summary: [TITLE]
- Assignee: James Baldwin
- Status: In Progress

Description:
[FORMATTED_DESCRIPTION]`,
  output: "Return the issue key and URL"
})
```

### 3. Move to Current Sprint

After creating the ticket, move it to the current sprint:

```
zapier-mcp_execute_write_action({
  app: "jira",
  action: "move_issue_to_sprint",
  instructions: "Move [TICKET_KEY] to the current active sprint for AGP",
  output: "Confirm the sprint assignment"
})
```

### 4. Report to James

Provide:

- Ticket key (e.g., AGP-1146)
- Direct URL to the ticket
- Confirmation of sprint assignment

## Description Formatting

Structure the description as:

```markdown
**Summary**
[Brief explanation of what was broken]

**Root Cause**
[Technical explanation of why it broke]

**Fix**
[What was changed to fix it, including file:line if relevant]

**Introduced in**
[MR/commit reference if known, otherwise "Unknown"]
```

## Example Usage

### Example 1: Bug with full context

**User:** "quick bug: ensureZapierActions uses wrong user ID type - was passing zapierCustomUserId instead of user.id for the Action FK, caused constraint violations. Fixed in mcp-server-permissions.ts:177. Introduced in MR !251 by Lucas."

**Assistant:**

1. Creates AGP ticket with formatted description
2. Assigns to James Baldwin
3. Sets to In Progress
4. Moves to current sprint
5. Reports: "Created AGP-1147: https://zapierorg.atlassian.net/browse/AGP-1147 (added to current sprint)"

### Example 2: Simple bug

**User:** "log a bug for the null pointer in webhook handler"

**Assistant:**

1. Creates ticket with available info
2. Asks James for any additional context if description is too sparse
3. Reports ticket details

## Important Notes

- **Always use AGP (MCP)** as the project - never guess or use other projects
- **Keep summaries concise** - the description holds the detail
- **Include code references** when available (file:line format)
- **Link to MRs** when the introduction point is known

## Success Criteria

1. Ticket created in AGP (MCP) project
2. Assigned to James Baldwin
3. Status set to In Progress
4. Added to current sprint
5. James receives ticket key and URL
