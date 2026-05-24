---
name: github-issue-workflow
description: 'GitHub issue triage, creation, updates, issue-to-PR execution, and agent handoff prompts. Use when James asks to review GitHub issues, close/update/create issues, pick issues for parallel agents, work on GitHub issue #N, or put up a GitHub PR for an issue.'
---

# GitHub Issue Workflow

Use this skill for GitHub issue work in James's own repos, especially `jwbaldwin/annie`. It covers issue triage, issue creation/update, selecting independent issues for agents, and turning one issue into a small PR.

Default to the current repository when the request is made from a repo checkout. If the repo is ambiguous, ask one short question before using GitHub.

## Route The Request

Classify the request first:

| Request | Path |
| --- | --- |
| "look at issues", "can any be closed", "clean up issues" | Issue triage |
| "create a ticket/issue", "update issue" | Issue write-up |
| "find 3 tickets for agents" | Parallel-agent prompt selection |
| "work on issue #N", "tackle GitHub issue #N" | Issue-to-PR execution |
| "put up a PR" after an issue fix | GitHub PR creation |

Prefer `gh` for GitHub source-of-truth operations. Use Jujutsu for local version control; do not use Git commit workflows unless James explicitly asks.

Always invoke the `writing-style` skill before drafting issue bodies, issue updates, PR descriptions, triage summaries, or parallel-agent prompts.

## Shared Setup

1. Identify the repository from the local remote, issue URL, or James's request.
2. Check `gh auth status` if GitHub access is needed.
3. Read the issue or issue list from GitHub before making claims.
4. Confirm local worktree state before code edits: use `jj status` and preserve unrelated changes.
5. For Annie, read `AGENTS.md`, `docs/DESIGN_PRINCIPLES.md`, and `docs/CODE_STYLE_GUIDANCE.md` before implementation work.

## Issue Triage

Use this when James asks whether issues can be closed, renamed, updated, split, or kept open.

1. List relevant open issues with `gh issue list` or inspect specific issue URLs/numbers.
2. For each candidate, check current repo state before deciding it is done.
3. Classify each issue as `close`, `keep`, `update`, `split`, or `needs James`.
4. Do not close issues without James's explicit approval.
5. When updating an issue, ground the body in current code and use concise acceptance criteria.

Triage output shape:

```markdown
| Issue | Recommendation | Evidence | Next action |
| --- | --- | --- | --- |
| #67 | keep | fallback path still missing browser/XHR behavior | implement narrow controller coverage |
```

## Issue Write-Up

Use this for creating or updating issues.

1. Search first for duplicates or related existing issues.
2. Keep the title action-oriented and specific.
3. Write the body as: context, desired behavior, implementation notes, validation.
4. Avoid broad roadmap language unless James asked for planning.
5. If the issue came from a production bug, include the observable symptom and the narrow suspected boundary.

Default issue body:

```markdown
## Context
One or two sentences on why this exists

## Goal
- Concrete outcome
- Concrete non-goal if scope could sprawl

## Implementation notes
- Smallest likely code path
- Existing boundary to reuse

## Validation
- Focused tests or command
```

## Parallel-Agent Prompt Selection

Use this when James wants several independent Codex/OpenCode agents to work in parallel.

Pick issues that are small, independent, testable, and unlikely to touch the same files. Avoid issues that require product direction, broad migrations, secrets, or architectural choices.

Prompt shape:

```text
Tackle GitHub issue #N in the <repo> repo.

Goal: <one concrete outcome>.

If anything is ambiguous, ask James. Otherwise keep it simple and make the smallest clean slice. Follow the repo instructions, use Jujutsu rather than Git commits, preserve unrelated worktree changes, and use the existing tests/factories/stubs if needed.

When done, run the relevant focused tests, then put up a GitHub PR with a concise description.
```

## Issue-To-PR Execution

Use this when James asks to tackle a GitHub issue directly.

1. Read the issue, linked PRs, and relevant code.
2. State the smallest implementation plan if the work is non-trivial.
3. Create or switch to an appropriate jj bookmark/workspace only when needed.
4. Implement the smallest correct change; avoid speculative cleanup.
5. Add or update tests at the external boundary when possible.
6. Run focused tests, then repo precommit if appropriate.
7. Create a GitHub PR with `gh pr create` after the branch/bookmark is pushed.

PR description shape:

```markdown
One sentence summary

- What changed
- Why the reviewer should care
- Test coverage

Closes #N
```

## Guardrails

- Do not use GitLab-only skills for GitHub issues unless James is explicitly working in GitLab.
- Do not close, delete, or heavily rewrite issues without explicit approval.
- Do not expose secrets, production data, PHI, or raw webhook payloads in issues or PR descriptions.
- Prefer one issue per PR unless James asks to batch related work.
- Keep agent prompts scoped enough that a fresh agent can finish without rediscovering James's preferences.
