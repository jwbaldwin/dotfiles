---
name: work-on-ticket
description: Fetches Jira ticket details, creates an appropriately named branch, and initiates the task planning workflow. Use when the user says "work on [TICKET_ID]" or similar phrases.
license: MIT
allowed-tools: 
  - read
  - write
metadata:
  version: "1.0"
---

# Work on Ticket

Start work on a Jira ticket by fetching ticket details, making sure my jujutsu state is setup, and doing some initial research.

## When to Use This Skill

Activate this skill when:
- The user says "work on AGP-123" or "start work on AGP-123"
- The user says "pick up AGP-123" or "begin AGP-123"
- Pattern: `work on [TICKET_ID]` or similar intent

## Workflow

### 1. Parse Ticket ID

Extract the Jira ticket ID from the user's message. Common patterns:
- `work on AGP-782`
- `start AGP-782`
- `pick up PROJ-123`

Ticket ID format: `[A-Z]+-[0-9]+` (e.g., AGP-782, AICC-123)

### 2. Fetch Jira Ticket Details

Use the MCP Zapier tool to fetch the ticket:

```typescript
mcp__zapier-frontend__jira_software_cloud_find_issue_by_key({
  instructions: "Get details for ticket [TICKET_ID]",
  key: "[TICKET_ID]",
  fields: "summary,description,issuetype,priority,status"
})
```

**Extract from response:**
- Summary (title)
- Description
- Issue type
- Status
- Any other relevant context

### 3. Generate Jujutsu Bookmark Name

Create a branch name using this format:
```
[TICKET_ID]-[kebab-case-summary]

```

**Branch Naming Rules:**
- Start with the ticket ID (e.g., `agp-782-`) (lowercase)
- Convert summary to kebab-case (lowercase, dashes instead of spaces)
- Remove special characters
- Keep it concise (max 50 characters total)
- Use meaningful words

**Examples:**
- `agp-782-migrate-existing-mcp-server`
- `aicc-123-fix-auth-token-expiry`
- `proj-456-add-user-settings-page`

### 4. Check Current Jujutsu State

Before creating a new commit with Jujutsu, and bookmark, check the current state:

```bash
jj st
```

Because we use jujutsu, we do not need to commit any changes, but we do need to ensure that our new work is started from a new commit off of HEAD

```bash
# Ensure we're on the latest staging
jj git fetch
jj new main # create a new commit on top of main

# Create bookmark with description
jj describe -m '[a very short 50 character description of the the first commit]'
jj bookmark create [BOOKMARK_NAME]
```

Confirm to James: "Described and bookmarked [BOOKMARK_NAME]"

### 6. Build Task Planning Prompt

Analyze the Jira ticket and create a comprehensive prompt for the `/investigate` command:

**Prompt should include:**
- The ticket summary
- Key details from the description
- Any acceptance criteria mentioned
- Relevant technical context

**Example prompt construction:**
```
Summary: [ticket.summary]

Description: [ticket.description]

Acceptance Criteria:
[extracted criteria if present]
```

### 7. Execute Task Planning

Run the `/investigate` slash command with the ticket number and constructed prompt:

```bash
/investigate [TICKET_ID] [CONSTRUCTED_PROMPT]
```

**Example:**
```bash
/investigate AGP-782 Migrate existing MCP server implementation to new architecture

Description: We need to refactor the MCP server to use the new modular architecture. This includes updating the tool registry, migrating existing tools, and ensuring backward compatibility.

Acceptance Criteria:
- All existing tools work with new architecture
- Tests pass
- No breaking changes to API
```

## Example Usage

### Example 1: Simple Ticket

**User:** "work on AGP-782"

**Claude:**
1. Fetches AGP-782 from Jira
2. Finds summary: "Migrate existing MCP server"
3. Checks git state (clean, on staging)
4. Creates JJ bookmark and describe: `agp-782-migrate-existing-mcp-server`
5. Runs: `/investigate AGP-782 Migrate existing MCP server implementation...`

### Example 3: Ticket Not Found

**User:** "work on BAD-999"

**Claude:**
1. Tries to fetch BAD-999 from Jira
2. Ticket not found
3. Informs James: "Couldn't find ticket BAD-999 in Jira. Please check the ticket ID."
4. STOPS

## Important Notes

- **Keep bookmark names concise** - aim for clarity over completeness
- **Include ticket context** in the task planning prompt to give the planner maximum context
- **The `/investigate` command** will handle the detailed planning - this skill just sets up the environment

## Success Criteria

The skill is successful when:
1. ✅ Jira ticket is fetched successfully
2. ✅ Appropriate bookmark name is generated
3. ✅ Git state is verified (no uncommitted changes or user approved)
4. ✅ New bookmark is created and checked out
5. ✅ `/investigate` command is executed with ticket context
6. ✅ James is informed of each major step OR any issues encountered stop the workflow and are reported

