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

```bash
jj status
jj diff
jj log
```

Understand what's in the working copy and what logical boundaries exist.

## Step 2: Analyze Logical Groupings

Our converstation will likely have clues about how to group changes.

You can also review the diff and identify natural separation points:

| Grouping Strategy | Example |
|-------------------|---------|
| By file/module | Frontend changes vs backend changes |
| By concern | Refactoring vs new features vs bug fixes |
| By dependency | Changes that depend on each other vs independent changes |
| By reviewability | Small, easy-to-review chunks |

Think about what would make sense as separate commits for code review and history.

## Step 3: Create Logical Commits

**CRITICAL:** Do NOT use `jj split -i` (interactive mode) - it will hang the session.

Instead, use this approach:

1. Create a new change for the first logical group:
```bash
jj new
```

2. Move specific files/paths or changes into this change:
```bash
jj file move <path> --from <parent-change-id>
```

3. Use the **commit skill** to describe and finalize each change — it handles message style and the `jj describe` + `jj new` workflow.

4. Repeat for each logical grouping.

**Alternative approach** if file-level granularity isn't enough:

1. Use `jj squash` to selectively move changes:
```bash
jj squash -i --from <source> --into <destination>
```

2. Or use `jj restore` to selectively stage:
```bash
jj new
jj restore --from <parent> <paths>
```

Then use the **commit skill** to write the message and finalize.

## Step 4: Verify Separation

```bash
jj log -r 'mine()'
```

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
