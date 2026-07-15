---
name: babysit
description: Monitor a GitLab MR through CI, merge eligibility, Greptile review, and teammate feedback until it is merge-ready or James must decide. Use when James says "babysit", "babysit this MR", "watch CI", "wait for CI", "babysit the MR", or "watch Greptile".
---

# MR Babysitter

## Objective

Own the active GitLab merge request until exactly one of these terminal outcomes:

- The MR is fully mergeable.
- The MR is merged or closed.
- James must make a decision or provide access that cannot safely be inferred.

Do not end the session after a single successful pipeline, a new push, or an `idle` snapshot. A babysit request means this thread continues polling and acting until a terminal outcome.

"Fully mergeable" means the newest MR head SHA has a successful relevant pipeline, GitLab reports no merge conflict or mergeability blocker, all required approvals are satisfied, and there is no unresolved actionable Greptile or teammate feedback.

## Scope And Safety

- Work only on the MR source bookmark and never force-push or rewrite published history.
- Use Jujutsu. Create each fix as a new commit with `jj describe` followed by `jj new`; never use `jj squash`.
- Before editing, inspect the working copy. If unrelated uncommitted changes would make the fix unsafe, stop and ask James.
- Make the smallest correct fix. Do not turn CI or review remediation into a cleanup or refactor.
- Never merge, deploy, alter production configuration, change MR metadata, assign reviewers, or modify approvals without James's explicit instruction in this conversation.
- Never post a conversational GitLab note, comment, reply, reaction, or thread-resolution on James's behalf. This includes replies to both teammates and Greptile.
- The only exception is the non-conversational Greptile command below, which exists solely to trigger a new bot review. The only other GitLab writes are pushes for a validated fix and one retry of a clearly flaky failed job.

## Repository Mapping

| Repository | Path | Project ID | GitLab Path |
|---|---|---:|---|
| MCP | `/Users/jbaldwin/repos/mcp` | `71810865` | `zapier/team-agents-platform/mcp` |
| AI Command Center | `/Users/jbaldwin/repos/ai-command-center` | `48901663` | `zapier/zapai/ai-command-center` |

Accept an MR URL or infer the MR only when the current source bookmark maps unambiguously to one open MR. Otherwise ask James for the MR URL.

## Initial Snapshot

Before doing any write, fetch the current MR state and record:

- Project ID, MR IID, URL, title, source bookmark, target branch, and current head SHA.
- `state`, `detailed_merge_status`, `has_conflicts`, `merge_status`, and draft status.
- Latest pipeline for the current head SHA and all failed, pending, blocked, manual, or skipped jobs.
- Required approval status.
- All unresolved discussions and notes, including author, timestamp, file/line when present, body, resolution status, and whether the item has already been addressed by the current head SHA.

Use GitLab's read APIs or CLI. Useful endpoints:

```text
GET /projects/<project_id>/merge_requests/<iid>
GET /projects/<project_id>/merge_requests/<iid>/pipelines?per_page=20
GET /projects/<project_id>/pipelines/<pipeline_id>/jobs?per_page=100
GET /projects/<project_id>/jobs/<job_id>/trace
GET /projects/<project_id>/merge_requests/<iid>/approval_state
GET /projects/<project_id>/merge_requests/<iid>/discussions?per_page=100
```

When a push occurs, discard prior pipeline and review conclusions. Re-fetch the MR and watch only state for the new head SHA.

## Continuous Monitoring Loop

Start monitoring immediately and continue in this session. Poll roughly every 60 seconds while CI, mergeability, Greptile, or approvals are pending. Report changes and occasional heartbeats, not repetitive unchanged snapshots.

On every poll, process in this order:

1. Confirm the MR is still open. If it is merged or closed, report that terminal state and stop.
2. Refresh the head SHA, pipeline, merge status/conflicts, approvals, and unresolved discussions.
3. Check new teammate feedback before making a CI or mergeability change.
4. Triage new Greptile feedback before retrying a flaky job. A Greptile fix creates a new SHA, so do not retry old-SHA jobs when a fix is imminent.
5. Diagnose failed CI, downstream merge conflicts, and other branch-owned merge blockers.
6. If the MR is fully mergeable, report the merge-ready state and stop.
7. Otherwise wait and poll again, unless an issue requires James.

After every push, job retry, conflict-resolution push, or Greptile re-review request, return to the top of this loop immediately. Never leave a detached monitor process and end the turn while babysitting remains active.

## CI Failures

For each failed or cancelled job, fetch the trace and classify it before acting:

- `branch-related`: the trace implicates code under review, such as a compile, type, lint, test, snapshot, or static-analysis failure in the changed behavior. Make the smallest correct repair, run the relevant local check, commit, push the source bookmark, and resume monitoring.
- `flaky-or-infrastructure`: transient runner, network, registry, service, timeout, or CI-platform failure unrelated to this MR. Retry the failed job once only after reading the trace. If it fails again, report the evidence and stop for James.
- `unrelated-trunk`: a failure outside the MR's changes that is also plausibly broken on the target branch. Report the evidence and stop for James; do not alter unrelated code merely to make the pipeline green.
- `unclear`: perform one focused investigation. If responsibility remains ambiguous, stop and ask James rather than guessing.

Do not retry deployments or fix failures requiring secrets, external access, production actions, or an architectural/product judgment.

## Merge Eligibility And Conflicts

Check GitLab's detailed merge status and approval state on every loop, not only the pipeline badge.

When the MR has a downstream merge conflict or is no longer mergeable because the target branch advanced:

1. Inspect the target-branch changes and the conflict.
2. Resolve and test it only when the intended outcome is clear and the change stays within the MR's scope.
3. Create a new Jujutsu commit, push it, and resume the loop on the new SHA.
4. If resolving the conflict requires choosing product behavior, discarding either side's meaningful change, or a broad rebase/refactor, stop and give James the exact conflict and recommended resolution.

If approvals are the only remaining requirement, keep monitoring for new feedback and report that the MR is waiting on approval. Do not ask reviewers for approval or change approval state.

## Greptile Reviews

Treat Greptile feedback as autonomous remediation work, subject to the same code-safety rules as CI fixes. Identify Greptile by bot identity or unmistakable Greptile branding; do not rely on a single username.

Classify each newly surfaced Greptile finding:

- `actionable`: a concrete defect, missed test, broken edge case, or clear maintainability issue. Inspect the code, implement and test the smallest correct fix, commit, push, then request another review.
- `not-actionable`: an incorrect claim, a suggestion already covered by the current SHA, or a preference that conflicts with local conventions. Leave it untouched and record concise evidence in the final status.
- `needs-james`: a product, architecture, security, or other judgment call. Stop and ask James with the finding and the decision needed.

After pushing a commit that addresses one or more Greptile findings, submit exactly one non-conversational MR note to trigger a new review:

```text
@Greptile take another look
```

Do not add any other text, punctuation, explanation, or reply to the trigger or any Greptile discussion. Do not spam Greptile: request a re-review only after a new Greptile-remediation commit, not for CI-only changes or repeated polls. Continue monitoring until Greptile's resulting review has no unresolved actionable findings for the current SHA.

## Teammate Review Triage

Do not automatically implement, reply to, or resolve teammate-authored review feedback. When new teammate feedback arrives, stop and give James a concise triage item for every unresolved comment or thread:

```text
<reviewer> — <file:line or general discussion>
They said: <faithful short summary>
Assessment: <correct / incorrect / partially correct / needs clarification>
Recommendation: <the specific response, code change, or reason not to change>
Suggested action: <implement / James replies with drafted text / James asks reviewer a question / no action>
```

Include the original wording or a precise link when paraphrasing would lose technical meaning. If several comments share one root cause, group them but preserve each reviewer concern. State the smallest implementation plan and expected CI impact for recommendations to change code.

This is a terminal `needs-james` state. Resume only after James chooses the suggested action or gives another instruction. Provide drafts in chat if useful, but never post them to GitLab, even if James approves their wording.

## Commit And Push Rules

For every autonomous fix:

1. Read the relevant code and existing tests.
2. Apply the minimal change and add or update tests when behavior changes.
3. Run targeted checks first, then the repository-required checks that fit the change.
4. Create a new descriptive Jujutsu commit and push the source bookmark.
5. Report the commit SHA and a one-line reason, then immediately resume the monitoring loop.

Use commit subjects such as `Fix CI failure on !<iid>`, `Resolve merge conflict on !<iid>`, or `Address Greptile feedback on !<iid>`. Do not include unrelated changes in a babysit commit.

## Strict Stop Conditions

Stop only when one of these conditions holds:

- The MR merged or closed.
- The MR is fully mergeable.
- A teammate review requires James's decision.
- A Greptile finding requires James's decision.
- CI, merge conflict, approval, permissions, secrets, infrastructure, or scope ambiguity cannot be safely resolved autonomously.

Do not stop merely because CI is green when mergeability is unknown, conflicts exist, approval is pending, Greptile has not completed its current-SHA review, or actionable review feedback remains.

## Status Updates

Send short progress updates only when state changes: a failed job is diagnosed, a fix is pushed, Greptile is re-triggered, CI becomes green, a conflict appears or is resolved, a teammate comment arrives, or the MR reaches a terminal state.

For a merge-ready terminal state, report:

```text
Babysit complete: <MR title> (!<iid>)
  Head: <sha>
  CI: passing
  Mergeability: mergeable; no conflicts
  Approvals: satisfied
  Greptile: reviewed current SHA; no actionable findings
  Fixes pushed: <count and short subjects, or none>
  URL: <mr-url>
```

For a `needs-james` terminal state, state the blocker, relevant evidence or link, your recommendation, and the smallest decision or action required from James.
