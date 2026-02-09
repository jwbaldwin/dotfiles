---
name: deslop
description: Remove AI code slop and simplify code to achieve the same result with less complexity. Triggered by "deslop", "simplify", "clean up code", or "reduce complexity".
license: MIT
allowed-tools: 
  - read
  - write
  - edit
  - bash
  - glob
  - grep
metadata:
  version: "1.0"
---

# Deslop

Remove AI-generated slop AND simplify code to achieve the same result with less complexity.

## When to Use This Skill

Activate when James says:
- "deslop"
- "simplify"
- "clean up code"
- "reduce complexity"

## Step 1: Get the Diff

Review all changes introduced in this bookmark (jujutsu stack of commits). Or maybe just this one jj commit

## Step 2: Remove AI Slop

Identify and remove:

| Slop Type | Example |
|-----------|---------|
| Extra comments | Comments a human wouldn't add, or inconsistent with the file |
| Defensive overkill | Unnecessary try/catch blocks, null checks on trusted paths |
| Type escapes | Casts to `any` to work around type issues |
| Style drift | Patterns inconsistent with the rest of the file |

## Step 3: Simplify

Go beyond slop removal. Actively look for:

| Simplification | Before → After |
|----------------|----------------|
| Redundant code | Remove duplicate logic, combine similar branches |
| Over-abstraction | Inline single-use functions **only if clearer** |
| Verbose patterns | Replace with idiomatic alternatives |
| Dead code | Remove unreachable or unused code |
| Unnecessary state | Derive values instead of storing them |

**Guiding principle:** Can this achieve the same result with less code? If yes, simplify.

## Step 4: Verify

- Run type checker if applicable (`tsc --noEmit`, `pnpm typecheck`)
- Run tests if applicable
- Ensure behavior is unchanged

## Step 5: Report

Provide a 1-3 sentence summary of what was changed. Group by:
1. Slop removed
2. Simplifications made

## Example

```
Removed 12 unnecessary comments and 3 redundant try/catch blocks.
Simplified `processItems` by inlining the single-use `filterValid` helper
and replacing the manual loop with `Array.filter().map()`.
```
