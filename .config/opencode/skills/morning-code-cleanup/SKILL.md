---
name: morning-code-cleanup
description: Find and apply one small, reviewable MCP repo cleanup that improves codebase cleanliness without changing intended behavior. Use when James asks for a morning cleanup, tiny MR, 5-10 minute cleanup MR, codebase cleanliness improvement, entropy cleanup, cruft removal, tech-debt cleanup, DRY/YAGNI/KISS/SOLID cleanup, large-file chipping, readable architecture cleanup, naming cleanup, TODO cleanup, logging cleanup, or agentic-code cleanup.
---

# Morning Code Cleanup

Create one MCP repo MR that James can review and merge in 5-10 minutes.

The cleanup should make the codebase better to work in: less duplication, better names, clearer files, stronger local reasoning, fewer stale artifacts, or more consistent use of shared utilities. Style cleanup is valid, but meaningful readability and architecture cleanup should usually outrank pure style.

## Non-Negotiables

- Preserve intended behavior. Do not change product behavior, API contracts, validation, data shape, persistence, permissions, timing, generated output, or test intent.
- Logging cleanup is allowed when it fixes structured logging shape, improves human debugging, or applies a shared logger utility without changing the event's meaning.
- Optimize for 5-10 minute review, not an arbitrary line count. Good review shapes include a local rename, deleting stale code, replacing a one-off helper with a canonical helper, extracting a cohesive private helper into a well-named file, or moving a cohesive block with minimal edits.
- Make one cleanup only. One theme, one concept, one reviewable diff.
- Prefer deletion, consolidation, naming, extraction, and alignment with existing patterns over new abstractions.
- Do not introduce new dependencies.
- Do not edit generated artifacts unless the repo explicitly requires regeneration for the chosen cleanup.
- Do not make opportunistic drive-by changes.
- If no safe cleanup is obvious, stop and report the top candidates instead of forcing a change.

## Reviewable Diff Shape

Judge reviewability by cognitive load:

- The MR title and first sentence should explain the whole change.
- A reviewer should be able to scan the diff in 5-10 minutes.
- File movement is fine when most lines are moved verbatim into a better-named module.
- A rename across many files is fine when it is mechanical and the new name is obviously better.
- Avoid public API changes, cross-package ownership moves, mixed cleanup categories, broad import churn, and subtle type-system rewrites.
- If the diff needs a long explanation, it is too large or too clever for this skill.

## Cleanup Lanes

Prefer these in order unless the scanner finds a clearly better candidate:

1. **Chip away at large files**: extract a cohesive private function, parser, mapper, policy, fixture setup, or helper cluster into a well-named sibling file. The move should make the original file easier to read without changing logic.
2. **Reuse canonical helpers**: replace a local one-off with an existing utility, factory, fixture, mock, assertion, logger helper, schema helper, or repo convention.
3. **Collapse duplicated knowledge**: remove repeated test setup, assertions, validation snippets, mapper branches, literals, or local helper copies when the shared concept is obvious.
4. **Delete dead or stale code**: remove unused helpers, constants, branches, comments, TODOs, imports, or fixtures when tooling and local reading prove they are no longer useful.
5. **Improve names locally**: rename vague private variables, functions, types, tests, or files when the new name captures domain meaning and all call sites are easy to inspect.
6. **Reduce needless abstraction**: inline pass-through wrappers, remove unused parameters, or simplify a helper whose interface is as complex as its implementation.
7. **Tighten types without runtime change**: remove unnecessary casts, non-null assertions, `any`, or optionality only when the stronger type follows directly from existing contracts.
8. **Clean behavior-adjacent logging**: apply `createMcpLogger()`, fix Pino argument order, bind context once, or improve vague log messages when repo guidance makes the desired shape clear.
9. **Align style drift**: match repo conventions for imports, test helper taxonomy, or file organization. Good, but do not let style-only work dominate the rotation. Do not choose `!!` to `Boolean(...)` as a standalone cleanup; it is too low-value unless it supports a more meaningful same-module change.

## Design Principles

Use these principles as decision filters, not slogans:

- **DRY**: remove repeated knowledge, not merely repeated text.
- **KISS**: prefer the direct local change that makes code easier to scan.
- **YAGNI**: delete speculative options, flags, helpers, and comments.
- **SOLID / single responsibility**: keep each function/module focused on one reason to change.
- **High cohesion, low coupling**: move code only when it clearly belongs with code that changes for the same reason.
- **Information hiding**: do not leak framework, SDK, test, or persistence details across boundaries.
- **Local reasoning**: after the cleanup, a maintainer should need less surrounding context to understand the code.

## Workflow

### 1. Orient

Work in `/Users/jbaldwin/repos/mcp` unless James says otherwise.

Read `AGENTS.md`. Read `TESTING.md` before touching tests. If changing Codebox code action behavior, read `packages/core/src/code-actions/README.md`.

Check the working tree. Do not overwrite unrelated user changes. If the tree is dirty, work around unrelated edits and keep your diff isolated.

Run the MCP-specific scanner:

```bash
bash ~/.config/opencode/skills/morning-code-cleanup/scripts/find_cleanup_candidates.sh /Users/jbaldwin/repos/mcp
```

Use the scanner output as ranked leads, not proof. Confirm every candidate by reading nearby code and searching for existing patterns with `rg`.

### 2. Choose One Candidate

Pick the highest-value candidate that satisfies all of these:

- The behavior-preserving argument is obvious from local code, types, and tests.
- The MR can be reviewed in 5-10 minutes.
- The change has one sentence of review rationale.
- Existing tests or type/lint checks can verify it.
- The diff reduces concepts, duplication, naming ambiguity, file size pressure, stale artifacts, or inconsistency.

Before editing, state a candidate brief:

```text
Lane: <cleanup lane>
Files: <expected files>
Principle: <DRY/KISS/YAGNI/SRP/local reasoning/etc.>
Behavior safety: <why behavior stays the same>
Review shape: <why this is a 5-10 minute MR>
Verification: <commands>
```

Skip candidates that require product judgment, public contract changes, migrations, generated artifacts, timing/concurrency changes, broad architecture redesign, or subtle type-system heroics.

### 3. Apply The Smallest Good Fix

Make the smallest behavior-preserving patch that fully completes the chosen cleanup.

Prefer:

- extracting cohesive private code into a well-named sibling file when that makes a large file easier to scan;
- deleting unused code over moving it;
- reusing an existing helper over creating a new one;
- extracting a helper only when duplication is already real and the helper has one clear responsibility;
- local/private renames over exported renames, unless the exported name is clearly internal and mechanically updated;
- mechanical consistency fixes over clever simplifications.

After editing, inspect the full diff. If the diff no longer reads as one obvious cleanup, revert your own change and choose a smaller candidate.

### 4. Verify

Run the narrowest meaningful checks, then the repo's standard checks when practical:

- `pnpm fmt`
- `pnpm types`
- `pnpm lint`
- targeted tests if tests or behavior-adjacent code changed

For the final self-check, run:

```bash
git diff --stat
git diff --numstat
git diff --summary
```

Confirm the diff has one obvious theme and can be reviewed in 5-10 minutes.

### 5. Create The MR

Commit the cleanup. Use a concise message that names the cleanup, such as:

```text
Extract MCP request parsing helper
Remove stale OAuth test helper
Use structured MCP logger in connect route
Rename action needs mapper
```

Then use the `merge-request` skill to create the GitLab MR from the current jj bookmark. Follow that skill exactly, including asking James what the MR description should be if it requires that.

## MR Shape

Use a plain summary when asked for description text:

```markdown
## Summary
- <one sentence describing the cleanup>

## Why
- <DRY/KISS/YAGNI/SRP/local reasoning benefit>

## Verification
- `pnpm fmt`
- `pnpm types`
- `pnpm lint`
- <targeted test, if any>
```

Do not oversell. The ideal MR feels like, "yes, obviously."
