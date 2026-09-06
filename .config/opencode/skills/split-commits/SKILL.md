---
name: split-commits
description: Break big chunks of work into smaller, well-organized jj commits. Triggered by "split commits", "break up commits", "organize commits", or "jj split".
license: MIT
allowed-tools: 
  - read
  - write
  - edit
  - bash
  - glob
metadata:
  version: "1.0"
---

# Split Commits

This skill helps break large changes into smaller, logical jj commits for better code review and history.

## When to Use This Skill

Activate when James says:
- "split commits"
- "break up commits"
- "organize commits"
- "jj split"

This typically happens after a lot of work has been done and James forgot to ask for atomic commits upfront, and you forgot to do jj commits during your work. The changes are likely logically separable but currently lumped together.

## Step 1: Review Current State

Run from the repository root so filesets resolve against the intended paths:

```bash
cd "$(jj root)"
jj status
jj diff -r <revision>
jj log
jj help split
```

Identify the revision James wants split and its descendants. Record its full commit ID and the affected stack tip's full commit ID before rewriting, using `jj log -r <revision> --no-graph -T 'commit_id'`. These immutable IDs let you check that splitting preserved the final contents.

## Step 2: Analyze Logical Groupings

Our conversation will likely have clues about how to group changes.

You can also review the diff and identify natural separation points:

| Grouping Strategy | Example |
|-------------------|---------|
| By file/module | Frontend changes vs backend changes |
| By concern | Refactoring vs new features vs bug fixes |
| By dependency | Changes that depend on each other vs independent changes |
| By reviewability | Small, easy-to-review chunks |

Think about what would make sense as separate commits for code review and history.

## Step 3: Create Logical Commits

Use noninteractive splitting. Do not launch an interactive selector or description editor in an unattended session. Do not use `jj squash` unless James explicitly asks to squash two specific commits.

### Split By File

Select the paths for the first logical commit and supply its description:

```bash
jj split -r <revision> -m "first logical change" path/to/first path/to/second
```

The selected changes stay in the original change; the remainder becomes its child. Existing descendants are rebased. Inspect `jj log` after each split to identify the remainder's new change ID, then repeat on that revision. Do not reuse an old commit ID as the next split target.

Use the **commit skill** for message style and describe the resulting commits with `jj describe -r <change-id> -m "description"`. Splitting already creates the commits; do not insert empty `jj new` changes between them.

### Split Changes Within One File

Use `jj split` with a task-specific scripted diff editor instead of an interactive selector. Prepare a script outside the repository that receives the left and right directory paths. The left contains the parent tree; the right starts with the complete change. The script must:

- Leave the left directory unchanged
- Check the expected right-side contents before editing
- Change only the selected right-side files to the exact contents wanted in the first commit, preserving unrelated contents
- Exit nonzero if those expectations fail, and never prompt for input

With an available Python 3 interpreter, configure the editor only for this invocation:

```bash
jj --config 'merge-tools.split-hunks.program="python3"' \
  --config 'merge-tools.split-hunks.edit-args=["/absolute/path/select-hunks.py", "$left", "$right"]' \
  split -r <revision> -m "first logical change" \
  --tool split-hunks path/to/file
```

Jujutsu records the edited right tree as the first commit and puts the remaining changes in its child. Inspect both diffs immediately. If the selected contents cannot be established confidently, ask about the grouping rather than guessing or invoking squash.

## Step 4: Verify Separation

```bash
jj log -r '<first-change-id>::<new-stack-tip>'
jj diff --from <original-commit-id> --to <remainder-change-id> --summary
jj diff --from <original-stack-tip-commit-id> --to <new-stack-tip> --summary
```

Both comparisons must be empty: the split revision's combined contents and the affected stack tip must remain unchanged. If either differs, stop and inspect the mismatch before continuing. Check affected revisions for conflicts and inspect each resulting commit's diff.

Review the commit graph to ensure:
- Each commit is atomic and self-contained
- Commits are in logical order (dependencies first)
- Commit messages accurately describe the changes

## Step 5: Review Each Commit

For each new commit:
```bash
jj diff -r <change-id>
```

Ensure it makes sense on its own and would be easy to review.

## Tips

- **Start with the foundation:** Move infrastructure/refactoring commits first, then features that depend on them
- **Keep it atomic:** Each commit should represent one logical change
- **Don't overthink it:** Good enough is better than perfect — the goal is reviewability, not perfection
- **Delegate message writing** to the commit skill — it knows the style rules
