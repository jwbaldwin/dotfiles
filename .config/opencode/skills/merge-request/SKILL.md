---
name: merge-request
description: Create a GitLab merge request from the current jj bookmark. Triggered by "create MR", "create merge request", "open MR", "submit for review", or "put up the MR".
---

# Create Merge Request

Create a GitLab MR from the current jujutsu bookmark, push to GitLab, and assign reviewers.

## Repository Config

| Repository | Path | Project ID | Default Target | GitLab Path |
|------------|------|------------|----------------|-------------|
| MCP | `/Users/jbaldwin/repos/mcp` | 71810865 | `main` | `zapier/team-agents-platform/mcp` |
| AI Command Center | `/Users/jbaldwin/repos/ai-command-center` | 48901663 | `staging` | `zapier/zapai/ai-command-center` |

### Default Reviewers

| Name | GitLab Username |
|------|----------------|
| Nate Moore | `neat.moore` (ID: 16898407) |
| Dylan Laible | `dylan.laible` (ID: 31252789) |

## Workflow

### 1. Detect Repository

Check the current working directory to determine the repo. If unclear, ask James.

### 2. Gather Context

```bash
jj log -r 'mine()'    # see commit history
jj diff                # see current changes
jj bookmark list       # find the current bookmark name
jj st                  # check for uncommitted work
```

Extract:
- **Bookmark name** - this becomes the source branch (e.g., `agp-782-migrate-mcp-server`)
- **Ticket ID** - extract from bookmark name (e.g., `AGP-782`)
- **Commit messages** - from `jj log` for the commits in this stack

### 3. Push the Bookmark

Push the jj bookmark to GitLab:

```bash
jj git push --bookmark <bookmark-name>
```

If there are errors (e.g., bookmark not tracking remote), fix them:

```bash
jj bookmark track <bookmark-name>@origin  # if needed
jj git push --bookmark <bookmark-name>
```

### 4. Build MR Title

Format: `[TICKET-ID] Short description`

- Extract ticket ID from the bookmark name (uppercase it: `agp-782` -> `AGP-782`)
- Use the first commit message or bookmark description as the short description
- Keep it concise (under 72 chars)

Example: `[AGP-782] Migrate existing MCP server`

### 5. Get Description from James

**STOP. Do NOT write a description yourself. Do NOT proceed to step 6 until James has responded.**

Ask James: "What should the MR description be? Or should I leave it blank for you to fill in?"

- If James provides text, use it verbatim.
- If James says to leave it blank, use an empty description.
- If James doesn't respond or says anything ambiguous, use an empty description.

Never draft, summarize, or generate a description on your own — even if you have full context about the change. James writes his own MR descriptions.

### 6. Create the MR

Use Zapier MCP to create the merge request:

```
zapier-mcp_execute_write_action({
  app: "gitlab",
  action: "merge_request",
  params: {
    title: "[TICKET-ID] Description",
    project_id: "<project_id>",
    source_branch: "<bookmark-name>",
    target_branch: "<default-target>",
    description: "<description or empty>"
  }
})
```

### 7. Assign Reviewers

After creation, assign reviewers via the raw API. First resolve usernames to IDs if needed, then update the MR:

```
zapier-mcp_execute_write_action({
  app: "gitlab",
  action: "_zap_raw_request",
  params: {
    method: "PUT",
    url: "https://gitlab.com/api/v4/projects/<project_id>/merge_requests/<iid>",
    url: "https://gitlab.com/api/v4/projects/<project_id>/merge_requests/<iid>?reviewer_ids[]=16898407&reviewer_ids[]=31252789",
    body: ""
  }
})

### 8. Report

```
MR created: [TICKET-ID] Description (!<iid>)
  URL: https://gitlab.com/.../-/merge_requests/<iid>
  Reviewers: Nate Moore, Dylan Laible
  Target: <target_branch>
```

## Example

```
James: "create MR"

Agent: [checks jj state, finds bookmark agp-782-migrate-mcp-server]
Agent: "What should the MR description be? Or should I leave it blank?"

James: "leave it blank"

Agent: [pushes bookmark, creates MR with empty description, assigns reviewers]
Agent:
  MR created: [AGP-782] Migrate existing MCP server (!230)
    URL: https://gitlab.com/zapier/team-agents-platform/mcp/-/merge_requests/230
    Reviewers: Nate Moore, Dylan Laible
    Target: main
```

## Important Notes

- Always push the bookmark before creating the MR
- If no bookmark exists yet, prompt James to create one with `jj bookmark create`
- The MR is created as non-draft by default. If James says "draft MR" or "WIP", set the title prefix to `Draft: `
- If James specifies different reviewers, use those instead of the defaults
- If James specifies a target branch, use that instead of the default
