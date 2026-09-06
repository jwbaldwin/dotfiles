---
name: workspace
description: Create or remove isolated colocated jj+git clones with GitHub or GitLab origins and named bookmarks. Use when James says "new workspace", "create workspace", "use a workspace for this", "clean up workspace", "remove workspace", or "delete workspace".
---

# Workspace

Create independent colocated clones in a repo-sibling `workspaces/` directory. Use a local clone for speed, but always restore `origin` to the canonical GitHub or GitLab remote before doing any work.

Do not use `jj workspace add`: its additional working copies do not contain the real `.git` directory required by James's tools.

## Naming

- With a Jira ticket, use `[ticket-id]-[kebab-case-summary]`, such as `agp-123-fix-auth-redirect`.
- Otherwise, use a short kebab-case description, such as `fix-auth-redirect`.
- Keep the name lowercase, meaningful, and at most 50 characters. The directory and bookmark use the same name.
- Reuse a ticket summary already available in the conversation. Fetch it from Jira only when needed.

## Create

### 1. Resolve Paths And Canonical Origin

Run:

```bash
REPO_ROOT="$(jj root)"
REPO_PARENT="$(dirname "$REPO_ROOT")"

if [ "$(basename "$REPO_PARENT")" = "workspaces" ]; then
  WORKSPACES_DIR="$REPO_PARENT"
else
  WORKSPACES_DIR="$REPO_PARENT/workspaces"
fi

TARGET="$WORKSPACES_DIR/<workspace-name>"
jj git remote list -R "$REPO_ROOT"
```

Resolve `origin` to the canonical GitHub or GitLab URL before cloning:

- Accept SSH or HTTPS URLs for either host, such as `git@github.com:owner/repo.git`, `https://github.com/owner/repo.git`, `git@gitlab.com:group/repo.git`, or `https://gitlab.com/group/repo.git`.
- If `origin` is a local filesystem path from an older workspace, inspect that repository's `origin` and follow local paths until reaching GitHub or GitLab.
- Stop if there is no unambiguous canonical origin. Never leave a new workspace configured to push to another local clone.
- If `TARGET` already exists, stop and ask James what to do.

### 2. Choose The Base Bookmark

Use `main` unless James explicitly requests another base. The known exception is `zapier/zapai/ai-command-center`, which uses `staging`.

Do not use `trunk()`: a local clone can inherit a repo-local alias tied to the source checkout's current feature bookmark.

```bash
BASE_BOOKMARK="main" # Use "staging" for ai-command-center
```

### 3. Clone And Start From Current Remote Base

Use the current checkout as the local clone source for speed. Clone only the base bookmark, skip tags, restore the canonical remote as `origin`, fetch the latest base, and rebase the empty working-copy change onto it:

```bash
mkdir -p "$WORKSPACES_DIR"
jj git clone --colocate --fetch-tags none --branch "$BASE_BOOKMARK" "$REPO_ROOT" "$TARGET"
jj git remote set-url -R "$TARGET" origin "<canonical-origin>"
jj git fetch -R "$TARGET" --remote origin --branch "$BASE_BOOKMARK"
jj rebase -R "$TARGET" -r @ -o "${BASE_BOOKMARK}@origin"
jj describe -R "$TARGET" -m '<lowercase description without ticket id, max 50 chars>'
jj bookmark create -R "$TARGET" <workspace-name> -r @
```

If any command after cloning fails, stop and report the failed step and the partially created `TARGET`. Do not silently delete or reuse it.

### 4. Verify

Run all checks:

```bash
test -d "$TARGET/.git"
jj git remote list -R "$TARGET"
jj log -R "$TARGET" -r "@- & ${BASE_BOOKMARK}@origin" --no-graph
jj bookmark list -R "$TARGET" <workspace-name>
jj st -R "$TARGET"
```

Do not report success unless:

- `.git` is a real directory.
- `origin` is the canonical GitHub or GitLab URL, not a local path.
- `@` is an empty described change directly on the freshly fetched base bookmark.
- The requested bookmark points to `@`.

Report the full workspace path, bookmark, base revision, and canonical origin. Tell James to start OpenCode with:

```bash
opencode <full-workspace-path>
```

## Remove

### 1. Resolve And Inspect

Use the same path rule from creation. If the current repo's parent directory is named `workspaces`, that parent is `WORKSPACES_DIR`; otherwise use the repo-sibling `workspaces/` directory.

If James did not identify the workspace and more than one exists, ask which one. Never delete the checkout that contains the active process; run cleanup from another checkout.

Before deletion, inspect for work that may exist only locally:

```bash
jj st -R "$TARGET"
jj bookmark list -R "$TARGET"
jj git remote list -R "$TARGET"
```

If there are working-copy changes, unpushed commits, or a bookmark that is not present on the canonical remote, explain the risk and ask James before deleting. Do not ask whether to delete the local bookmark separately: deleting this independent clone removes its local bookmarks, while remote bookmarks are unaffected.

### 2. Delete And Verify

After any required confirmation:

```bash
rm -rf -- "$TARGET"

if [ -e "$TARGET" ]; then
  printf 'Workspace directory still exists: %s\n' "$TARGET" >&2
  exit 1
fi
```

Report the removed path and whether all work had reached the canonical remote. Never claim cleanup succeeded while `TARGET` still exists.
