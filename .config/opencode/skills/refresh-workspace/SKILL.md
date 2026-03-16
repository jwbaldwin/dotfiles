---
name: refresh-workspace
description: Refresh a jj workspace to pristine state at the tip of main after merging work. Use when the user wants to reuse a workspace for new work, especially after merging changes to main/trunk. Triggered by phrases like "refresh my workspace", "reset my workspace", "clean up this workspace", "reuse this workspace", or "workspace is ready for new work".
---

# Refresh Workspace

Refreshes a jj workspace to pristine state at the tip of main, preserving the workspace for reuse with new work.

## When to Use

Use this skill when:
- User has merged their work to main/trunk and wants to reuse the same workspace
- User wants to clean up a workspace that's now at main
- User wants to preserve a workspace but get back to "ready for work" state
- User explicitly asks to "refresh", "reset", "clean up", or "reuse" a workspace

## Safety First: Verify Before Abandoning

**CRITICAL:** Before abandoning any work, verify one of:
1. The working copy is empty (no changes, no commits)
2. The work has been merged to main/trunk

```bash
# Check working copy status
jj status

# Verify work is in main
jj log main..@  # Should show no commits if merged
# OR check if commits are empty or already on main
```

**If work is NOT merged and working copy is NOT empty:** STOP and ask user what to do.

## Workflow

### 1. Determine fetch strategy

Check what origin points to:

```bash
jj git remote list
```

**If origin points directly to GitHub (user's setup):**
```bash
jj git fetch
```

**If origin points to parent repo (~/repos/projects/annie):**
```bash
cd ~/repos/projects/annie && git fetch && cd -
```

### 2. Verify working copy state

```bash
jj status
jj log --limit 5
```

**If working copy has unmerged work:** STOP and report to user.

### 3. Abandon current work and create fresh empty commit on main

```bash
jj abandon @
jj new main
```

### 4. Handle bookmark

**If the user specified a bookmark name:**
```bash
jj bookmark create <bookmark-name> -r @
```

**If there's an existing bookmark that should be kept:**
```bash
jj bookmark set <existing-bookmark-name> -r @
```

**If no bookmark specified and no existing bookmark:**
Ask the user what bookmark name they'd like to use.

### 5. Verify final state

```bash
jj status
jj log --limit 5
jj bookmark list
```

## Example Usage

**User says:** "I just merged my todo-work branch to main. Can you refresh this workspace so I can use it again?"

**Execute:**
```bash
jj git remote list  # Check if origin is github or parent
jj git fetch        # If origin is github
jj status           # Verify empty or merged
jj abandon @
jj new main
jj bookmark set todo-work -r @
jj status
```

**User says:** "Clean up this workspace and give me a fresh start"

**Execute:**
```bash
jj status           # Verify it's safe to abandon
jj abandon @
jj new main
jj bookmark create todo-work -r @
```

## Safety Checks

### Check 1: Verify work is merged or empty

Before abandoning:
```bash
jj diff --stat      # Should be empty
jj log main..@      # Should be empty if work is merged
```

### Check 2: Handle parent repo vs GitHub origin

**Scenario A: Origin is GitHub (direct push)**
- Just run `jj git fetch`

**Scenario B: Origin is parent repo**
- Must `cd ~/repos/projects/annie && git fetch` then return

### Check 3: Verify clean state

After refresh:
```bash
jj status           # Should show empty working copy
jj log -r @         # Should show empty commit on main
```

## Edge Cases

- **Unmerged work detected:** STOP and ask user - don't abandon
- **No main bookmark:** Check for `trunk`, `master`, or ask user
- **Multiple bookmarks:** Ask which to keep, or create new one
- **Fetch fails:** Report error and ask user to check remote setup
- **Parent repo doesn't exist:** Fall back to `jj git fetch` and report

## Recovery

If something goes wrong:
```bash
jj undo             # Undo last operation
jj log --all        # Find the abandoned commit if needed
```
