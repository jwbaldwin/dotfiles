---
description: Run a thermo-nuclear code quality review of the current branch
---

# Thermo-Nuclear Code Quality Review

Perform a deep code quality audit of the current branch's changes using the `thermo-nuclear-code-quality-review` skill and subagent.

Use this flow:

1. Gather the current branch diff. Prefer `jj diff` in James's repos; use `git diff <base>...HEAD` only when that is the available VCS path.
2. Identify the files changed by the branch and read the full contents for the meaningful changed files.
3. Invoke the `thermo-nuclear-code-quality-review` subagent with the diff and changed-file contents.
4. Return findings first, ordered by severity and focused on structural maintainability issues. Do not bury findings under summary prose.

Additional user context:

$ARGUMENTS
