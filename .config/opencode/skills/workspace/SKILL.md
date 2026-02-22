---
name: workspace
description: Create or clean up jj workspaces in a repo-sibling workspaces directory (for example ~/repos/workspaces or ~/repos/projects/workspaces) for starting separate work without disturbing the current working copy. Triggered by "new workspace", "create workspace", "use a workspace for this" for creation, or "clean up workspace", "remove workspace", "delete workspace" for cleanup.
---

# Workspace

Create or clean up jj workspaces in a `workspaces/` directory that is a sibling of the current repo, with bookmarks, so James can start separate work without touching his current working copy.

Workspace root rule:
- Determine the current repo root with `jj root`.
- Set `WORKSPACES_DIR` to `<parent-of-repo-root>/workspaces`.
- Examples:
  - Repo at `~/repos/agent-platform` -> `WORKSPACES_DIR=~/repos/workspaces`
  - Repo at `~/repos/projects/agent-platform` -> `WORKSPACES_DIR=~/repos/projects/workspaces`

## Naming

Derive the workspace and bookmark name from context:

1. **Jira ticket mentioned** — use `[ticket-id]-[kebab-case-summary]` (e.g., `agp-123-fix-auth-redirect`). Fetch the ticket summary from Jira if needed, or use the description from conversation context.
2. **No ticket** — use a short kebab-case description of the work discussed (e.g., `fix-auth-redirect`, `add-metrics-export`)

**Bookmark naming rules** (same convention as `work-on-ticket` and `quick-fix`):
- All lowercase, kebab-case, max 50 chars
- When a ticket is involved, start with the ticket ID (e.g., `agp-123-`)
- Convert summary to kebab-case (lowercase, dashes instead of spaces)
- Remove special characters
- Use meaningful words

The workspace directory name should match the bookmark name.

Keep names short, lowercase, and descriptive. No prefixes like `ws-` or `workspace-`.

## Workflow

### Step 1: Determine the name

From conversation context, pick the workspace name using the rules above. If it's ambiguous, ask James.

### Step 2: Create the workspace

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
mkdir -p "$WORKSPACES_DIR"
jj workspace add -R "$REPO_ROOT" --name <workspace-name> "$WORKSPACES_DIR/<workspace-name>"
```

This creates a new working copy in the repo-sibling `workspaces/` directory, sharing the same repo storage.

### Crucial `.git` note

James relies on some tools that require a `.git` directory to exist in the workspace.

- `jj workspace add` creates non-main workspaces with `.jj` only (no `.git`).
- Immediately check whether `.git` exists in the new workspace path.
- If `.git` is missing, call it out to James right away and explain that this is current jj behavior.
- Do **not** copy or symlink `.git` manually as a workaround.
- If `.git` is required for the task, use a separate colocated repo (`jj git clone --colocate ...`) instead of a secondary `jj workspace add` workspace.

### Step 3: Create a bookmark

```bash
REPO_ROOT="$(jj root)"
jj bookmark create -R "$REPO_ROOT" <workspace-name> -r <workspace-name>@
```

The `<workspace-name>@` revision refers to the working copy of that workspace.

### Step 4: Confirm

```bash
REPO_ROOT="$(jj root)"
jj workspace list -R "$REPO_ROOT"
jj log -R "$REPO_ROOT" -r 'mine()'
```

Tell James:
- Where the workspace was created (the full path)
- The bookmark name
- That they can `cd` into `<workspaces-dir>/<workspace-name>` to work there

## Cleanup

Triggered by "clean up workspace", "remove workspace", or "delete workspace".

### Step 1: Identify the workspace

```bash
REPO_ROOT="$(jj root)"
jj workspace list -R "$REPO_ROOT"
```

If James doesn't specify which workspace, ask. If there's only one non-default workspace, confirm that's the one.

### Step 2: Forget the workspace in jj

```bash
REPO_ROOT="$(jj root)"
jj workspace forget -R "$REPO_ROOT" <workspace-name>
```

### Step 3: Ask about the bookmark

Check if a matching bookmark exists:

```bash
REPO_ROOT="$(jj root)"
jj bookmark list -R "$REPO_ROOT"
```

If a bookmark with the same name exists, **ask James** whether to delete it before proceeding. If yes:

```bash
REPO_ROOT="$(jj root)"
jj bookmark delete -R "$REPO_ROOT" <workspace-name>
```

### Step 4: Delete the workspace directory

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
rm -rf "$WORKSPACES_DIR/<workspace-name>"
```

### Step 5: Confirm

```bash
REPO_ROOT="$(jj root)"
jj workspace list -R "$REPO_ROOT"
```

Tell James the workspace has been removed and whether the bookmark was deleted.

## Tips

- If James chains this with **work-on-ticket**, the ticket ID and summary are already known — use `[ticket-id]-[kebab-case-summary]` without asking.
- The workspace shares the repo's storage, so no extra clone overhead.
- If a workspace with that name already exists, stop and ask James what to do rather than guessing.
- During cleanup, always ask about the bookmark — James may want to keep it even if the workspace is gone.
