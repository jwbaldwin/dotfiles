---
name: workspace
description: Create or clean up jj workspaces in ~/repos/workspaces/ for starting separate work without disturbing the current working copy. Triggered by "new workspace", "create workspace", "use a workspace for this" for creation, or "clean up workspace", "remove workspace", "delete workspace" for cleanup.
---

# Workspace

Create or clean up jj workspaces in `~/repos/workspaces/`, with bookmarks, so James can start separate work without touching his current working copy.

## Naming

Derive the workspace and bookmark name from context:

1. **Jira ticket mentioned** — use the ticket ID in lowercase kebab-case (e.g., `agp-123`)
2. **No ticket** — use a short kebab-case description of the work discussed (e.g., `fix-auth-redirect`, `add-metrics-export`)

Keep names short, lowercase, and descriptive. No prefixes like `ws-` or `workspace-`.

## Workflow

### Step 1: Determine the name

From conversation context, pick the workspace name using the rules above. If it's ambiguous, ask James.

### Step 2: Create the workspace

```bash
mkdir -p ~/repos/workspaces
jj workspace add <workspace-name> --path ~/repos/workspaces/<workspace-name>
```

This creates a new working copy in `~/repos/workspaces/`, sharing the same repo storage.

### Step 3: Create a bookmark

```bash
jj bookmark create <workspace-name> -r <workspace-name>@
```

The `<workspace-name>@` revision refers to the working copy of that workspace.

### Step 4: Confirm

```bash
jj workspace list
jj log -r 'mine()'
```

Tell James:
- Where the workspace was created (the full path)
- The bookmark name
- That they can `cd` into `~/repos/workspaces/<workspace-name>` to work there

## Cleanup

Triggered by "clean up workspace", "remove workspace", or "delete workspace".

### Step 1: Identify the workspace

```bash
jj workspace list
```

If James doesn't specify which workspace, ask. If there's only one non-default workspace, confirm that's the one.

### Step 2: Forget the workspace in jj

```bash
jj workspace forget <workspace-name>
```

### Step 3: Ask about the bookmark

Check if a matching bookmark exists:

```bash
jj bookmark list
```

If a bookmark with the same name exists, **ask James** whether to delete it before proceeding. If yes:

```bash
jj bookmark delete <workspace-name>
```

### Step 4: Delete the workspace directory

```bash
rm -rf ~/repos/workspaces/<workspace-name>
```

### Step 5: Confirm

```bash
jj workspace list
```

Tell James the workspace has been removed and whether the bookmark was deleted.

## Tips

- If James chains this with **work-on-ticket**, the ticket ID is the obvious name — don't ask.
- The workspace shares the repo's storage, so no extra clone overhead.
- If a workspace with that name already exists, stop and ask James what to do rather than guessing.
- During cleanup, always ask about the bookmark — James may want to keep it even if the workspace is gone.
