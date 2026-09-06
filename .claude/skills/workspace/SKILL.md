---
name: workspace
description: Create or clean up colocated jj+git clones in a repo-sibling workspaces directory (for example ~/repos/workspaces or ~/repos/projects/workspaces) for isolated work that still has a real .git directory. Triggered by "new workspace", "create workspace", "use a workspace for this" for creation, or "clean up workspace", "remove workspace", "delete workspace" for cleanup.
---

# Workspace

Create or clean up colocated `jj git clone --colocate` working copies in a `workspaces/` directory that is a sibling of the current repo, with bookmarks, so James can start separate work without touching his current working copy and still have `.git` available.

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

### Step 2: Create the colocated clone

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
mkdir -p "$WORKSPACES_DIR"
TARGET="$WORKSPACES_DIR/<workspace-name>"

# Local colocated clone from the current repo root
jj git clone --colocate "$REPO_ROOT" "$TARGET"
```

This creates a new working copy in the repo-sibling `workspaces/` directory that includes a real `.git` directory.

### Crucial `.git` note

James relies on some tools that require a `.git` directory to exist in the workspace.

- Immediately check whether `.git` exists in the new clone path.
- If `.git` is missing, stop and report failure instead of attempting manual workarounds.
- Do **not** copy or symlink `.git` manually.

### Step 3: Create a bookmark

```bash
TARGET="<workspaces-dir>/<workspace-name>"
jj bookmark create -R "$TARGET" <workspace-name> -r @
```

Create the bookmark inside the colocated clone repo so the workspace starts on a named branch/bookmark.

### Step 4: Confirm

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
TARGET="$WORKSPACES_DIR/<workspace-name>"

test -d "$TARGET/.git"
jj log -R "$TARGET" -r 'mine()'
```

Tell James:
- Where the workspace was created (the full path)
- The bookmark name
- That `.git` exists in the workspace
- That they can `cd` into `<workspaces-dir>/<workspace-name>` to work there

## Cleanup

Triggered by "clean up workspace", "remove workspace", or "delete workspace".

### Step 1: Identify the workspace

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
ls "$WORKSPACES_DIR"
```

If James doesn't specify which workspace, ask. If there's only one directory in `workspaces/`, confirm that's the one.

### Step 2: Ask about the bookmark

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
TARGET="$WORKSPACES_DIR/<workspace-name>"
jj bookmark list -R "$TARGET"
```

If a bookmark with the same name exists in the colocated clone, **ask James** whether to delete it before proceeding. If yes:

```bash
jj bookmark delete -R "$TARGET" <workspace-name>
```

### Step 3: Delete the workspace directory

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
TARGET="$WORKSPACES_DIR/<workspace-name>"
rm -rf -- "$TARGET"

# Hard verification: never report success unless this passes
if [ -e "$TARGET" ]; then
  echo "Workspace directory still exists: $TARGET" >&2
  exit 1
fi
```

### Step 4: Confirm

```bash
REPO_ROOT="$(jj root)"
WORKSPACES_DIR="$(dirname "$REPO_ROOT")/workspaces"
ls "$WORKSPACES_DIR"
```

Tell James the workspace has been removed and whether the bookmark was deleted. If the directory still exists after Step 3, stop and report failure instead of claiming cleanup is complete.

## Tips

- If James chains this with **work-on-ticket**, the ticket ID and summary are already known — use `[ticket-id]-[kebab-case-summary]` without asking.
- Use colocated clone creation every time instead of `jj workspace add` so `.git` is available by default.
- If a workspace with that name already exists, stop and ask James what to do rather than guessing.
- During cleanup, always ask about the bookmark — James may want to keep it even if the workspace is gone.
- During cleanup, run deletion and verification as separate checks; do not rely on a single combined command to infer success.
