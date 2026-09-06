---
name: simplify
description: Review changed code for reuse, quality, and efficiency, then simplify it without changing behavior. Use when James says "simplify" or asks to clean up code, reduce complexity, or refactor a change into a cleaner version. Prefer this skill for generic simplification requests.
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

# Simplify

Review all changed files for reuse, quality, and efficiency. Fix any issues found.

Prefer this skill for generic simplification work.

If the real problem is mostly AI-slop cleanup rather than broader code review, use the `/deslop` command instead of forcing the full simplify workflow. Typical signs: comment spam, defensive overkill, awkward casts, noisy helpers, or obvious style drift from the surrounding code.

## Phase 1: Identify Changes

Use `jj diff` for the working copy, or `jj diff -r <revision>` for a named change. Review the files or revision James requested. If that diff is empty, inspect the files he named or the changes you made earlier in this conversation rather than widening the scope.

Before continuing, decide whether this is actually a `/deslop` task. If most of the value is removing AI-generated slop while preserving behavior, prefer `/deslop`. If the work also needs reuse review, structural cleanup, or efficiency improvements, stay in this skill.

## Phase 2: Review Reuse, Quality, And Efficiency

For small changes, review all three perspectives directly. Delegate independent, substantial review work when it would improve coverage or save time. Use the current harness's supported delegation tool and follow its discovery, execution, and permission rules; do not assume a particular tool name or interface.

Choose the number of reviewers to fit the work, rather than always launching three. Give each reviewer the requested diff, relevant context, a distinct review focus, and a read-only boundary. If delegation is unavailable before launch, complete the review directly. If a launched run fails, follow the harness's failure-recovery rules.

### Code Reuse Review

For each change:

1. **Search for existing utilities and helpers** that could replace newly written code. Look for similar patterns elsewhere in the codebase — common locations are utility directories, shared modules, and files adjacent to the changed ones.
2. **Flag any new function that duplicates existing functionality.** Suggest the existing function to use instead.
3. **Flag any inline logic that could use an existing utility** — hand-rolled string manipulation, manual path handling, custom environment checks, ad-hoc type guards, and similar patterns are common candidates.

### Code Quality Review

Review the same changes for hacky patterns:

1. **Redundant state**: state that duplicates existing state, cached values that could be derived, observers/effects that could be direct calls
2. **Parameter sprawl**: adding new parameters to a function instead of generalizing or restructuring existing ones
3. **Copy-paste with slight variation**: near-duplicate code blocks that should be unified with a shared abstraction
4. **Leaky abstractions**: exposing internal details that should be encapsulated, or breaking existing abstraction boundaries
5. **Stringly-typed code**: using raw strings where constants, enums (string unions), or branded types already exist in the codebase
6. **Unnecessary JSX nesting**: wrapper Boxes/elements that add no layout value — check if inner component props (flexShrink, alignItems, etc.) already provide the needed behavior
7. **Vague or mechanism-driven names**: names that describe API mechanics, data shape, or generic containers instead of the job the code does. Flag bucket names (`input`, `payload`, `data`, `source`, `files`) where the thing has a specific role, helpers/modules whose names don't say the work being done, and client methods named after the provider endpoint rather than the caller's intent. If a name could fit ten unrelated places, it's too generic — suggest a name that says what job the code does from the caller's point of view.

### Efficiency Review

Review the same changes for efficiency:

1. **Unnecessary work**: redundant computations, repeated file reads, duplicate network/API calls, N+1 patterns
2. **Missed concurrency**: independent operations run sequentially when they could run in parallel
3. **Hot-path bloat**: new blocking work added to startup or per-request/per-render hot paths
4. **Unnecessary existence checks**: pre-checking file/resource existence before operating (TOCTOU anti-pattern) — operate directly and handle the error
5. **Memory**: unbounded data structures, missing cleanup, event listener leaks
6. **Overly broad operations**: reading entire files when only a portion is needed, loading all items when filtering for one

## Phase 3: Fix Issues

If you delegated reviews, collect their results before editing. Assess the findings from all three perspectives and fix the worthwhile issues within the requested scope. Skip false positives and changes that would not improve the code.

When done, briefly summarize what was fixed (or confirm the code was already clean).
