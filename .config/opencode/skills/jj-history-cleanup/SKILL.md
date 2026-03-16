---
name: jj-history-cleanup
description: Clean up Jujutsu history and workspace state. Use when James asks to clean up `jj` history/state, remove old workspaces, prune empty commits, fetch `trunk()` (`main`/`staging`), rebase stacks onto trunk, or generally tidy repo-sibling `workspaces/` clones without losing active work.
---

# Jj History Cleanup

Clean up Jujutsu state without discarding active work. Focus on safe workspace deletion, pruning only truly disposable empty commits, fetching trunk, and rebasing live stacks onto the latest trunk.

## Workflow

1. Inspect the current repo state.
2. Inspect repo-sibling `workspaces/` directories if they exist.
3. Fetch before deciding whether old workspaces are merged.
4. Delete only clearly safe workspaces.
5. Rebase live stacks onto `trunk()`.
6. Report what changed and call out anything that still needs James's decision.

## Inspect First

Always use `jj`, not `git`.

Start with the current repo:

```bash
jj status
jj workspace list
jj log -r 'trunk()' --no-graph
jj log -r 'mine() & ~::trunk()'
```

If a sibling `workspaces/` directory exists, inspect each candidate clone/workspace before touching it:

```bash
jj status
jj bookmark list
jj log -r 'ancestors(@) & mutable() & ~::trunk()'
```

Look for three categories:

- Safe to delete: clean workspace, no active local work, already parked on `trunk()` or clearly merged.
- Keep and rebase: active branch/bookmark or mutable commits not on `trunk()`.
- Ask James: dirty workspace, unclear merge status, or anything that looks like it might strand work.

## Delete Safely

Forget jj workspaces before deleting their directories:

```bash
jj workspace forget <workspace-name>
```

Then remove the directory from disk.

For standalone clones inside repo-sibling `workspaces/`, only delete the directory after verifying the clone is clean and the relevant work is merged to `trunk()`.

If a workspace is dirty, unmerged, or ambiguous, stop and ask James one targeted question. Do not guess.

## Prune Empty Commits

Do not treat the active working-copy commit `@` as garbage. Jujutsu normally keeps an empty working-copy commit.

Do not remove empty merge commits that are part of `trunk()` history.

Only prune empty commits when they are all of the following:

- outside `::trunk()`
- not needed by a live workspace
- not carrying the user's active work
- clearly disposable after workspace cleanup or fetch

Often `jj git fetch` or `jj workspace forget` will auto-abandon unreachable empty commits. If extra cleanup is still needed, use `jj abandon <revset>` carefully.

## Fetch Trunk

Fetch before merge checks or rebases:

```bash
jj git fetch
jj log -r 'trunk()' --no-graph
```

Remember that `trunk()` may resolve to `main` or `staging` depending on repo config.

After fetch, re-run `jj status` because fetch may auto-abandon unreachable commits or move a working copy to a new empty `@` commit.

## Rebase Live Stacks

For the current workspace or clone, find the local stack roots that are not already on trunk:

```bash
jj log -r 'roots(ancestors(@) & mutable() & ~empty() & ~::trunk())'
```

If that revset returns commits, rebase the stack onto trunk:

```bash
jj rebase -s 'roots(ancestors(@) & mutable() & ~empty() & ~::trunk())' -d trunk()
```

Run that per workspace/clone you are keeping.

Then verify:

```bash
jj status
jj log -r 'mine() & ~::trunk()'
```

## Report Back

Summarize:

- which workspaces/clones were deleted
- which stacks were rebased
- which empty commits were auto-pruned or abandoned
- which workspaces still need James to decide

If fetch or rebase changed a dirty workspace unexpectedly, say so plainly and describe the new state.
