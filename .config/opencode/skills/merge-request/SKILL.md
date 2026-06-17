---
name: merge-request
description: Create a GitLab merge request from the current jj bookmark. Triggered by "create MR", "create merge request", "open MR", "submit for review", or "put up the MR".
---

# Create Merge Request

Create a GitLab MR from the current jujutsu bookmark, push to GitLab, and assign reviewers, assign myself as the asignee (james.baldwin.z)

## Repository Config

| Repository | Path | Project ID | Default Target | GitLab Path |
|------------|------|------------|----------------|-------------|
| MCP | `/Users/jbaldwin/repos/mcp` | 71810865 | `main` | `zapier/team-agents-platform/mcp` |
| AI Command Center | `/Users/jbaldwin/repos/ai-command-center` | 48901663 | `staging` | `zapier/zapai/ai-command-center` |

### Default Reviewers

Pick **two** of these at random for each MR — never add more than two.

| Name | GitLab Username |
|------|----------------|
| Nate Moore | `neat.moore` (ID: 16898407) |
| Dylan Laible | `dylan.laible` (ID: 31252789) |
| Marco Costa | `marco.costa6` (ID: 35597336) |
| Daniel Vagg | `daniel.vagg` (ID: 23002286) |

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

The branch must end up on GitLab (gitlab.com), not just on a local clone.

First check where `origin` points:

```bash
jj git remote list
```

**If `origin` is gitlab.com** (e.g. `git@gitlab.com:zapier/...`), push the jj bookmark directly:

```bash
jj git push --bookmark <bookmark-name>            # add --allow-new for a brand new bookmark
```

If there are errors (e.g., bookmark not tracking remote), fix them:

```bash
jj bookmark track <bookmark-name>@origin  # if needed
jj git push --bookmark <bookmark-name>
```

**If you're in a workspace** (`origin` is a local clone path like `/Users/jbaldwin/repos/mcp`, not gitlab.com), `jj git push` only updates that local clone — GitLab never sees the branch. We don't care about the workspace's local origin; we want GitLab. So push the bookmark into the local clone, then push from the clone up to GitLab:

```bash
jj git push --bookmark <bookmark-name> --allow-new        # lands the branch in the local clone
git -C <clone-path> push -u origin <bookmark-name>         # clone-path = the local origin, e.g. /Users/jbaldwin/repos/mcp
```

Confirm GitLab actually has the branch before creating the MR. If MR creation fails with `source_branch: does not exist`, the branch did not reach GitLab — re-check this step.

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

After creation, pick **two** reviewers at random from the default list and assign them via the raw API. Never assign more than two.

Use the **comma-separated** `reviewer_ids` form: `reviewer_ids=ID1,ID2`. Do NOT use the `reviewer_ids[]=a&reviewer_ids[]=b` array form — through the Zapier raw request the repeated brackets collapse to a single value, so only one reviewer sticks.

```
zapier-mcp_execute_write_action({
  app: "gitlab",
  action: "_zap_raw_request",
  params: {
    method: "PUT",
    url: "https://gitlab.com/api/v4/projects/<project_id>/merge_requests/<iid>?reviewer_ids=<id1>,<id2>&assignee_id=29954463",
    body: ""
  }
})
```

`<id1>,<id2>` are two randomly chosen reviewer IDs from the default list; `assignee_id=29954463` is James. After the PUT, confirm the response `reviewers` array contains both names — if either is missing, that user is not a member of the project, so look up the correct member (there can be lookalike accounts with the same display name) and retry.

### 8. Report

```
MR created: [TICKET-ID] Description (!<iid>)
  URL: https://gitlab.com/.../-/merge_requests/<iid>
  Reviewers: <two randomly chosen, e.g. Dylan Laible, Marco Costa>
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
    Reviewers: Dylan Laible, Marco Costa
    Target: main
```

## Important Notes

- Always push the bookmark before creating the MR, and make sure it lands on **GitLab**, not just a workspace's local clone (see step 3)
- If no bookmark exists yet, prompt James to create one with `jj bookmark create`
- The MR is created as non-draft by default. If James says "draft MR" or "WIP", set the title prefix to `Draft: `
- If James specifies different reviewers, use those instead of the defaults
- If James specifies a target branch, use that instead of the default
