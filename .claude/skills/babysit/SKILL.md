---
name: babysit
description: Babysit a newly opened GitLab MR until it is review-ready: monitor CI, watch Greptile reviews, address actionable feedback, push fixes, ask @greptile for another review, and repeat. Triggered by "babysit", "babysit this MR", "watch CI", "wait for CI", "monitor greptile", or "babysit the MR".
---

# Babysit Merge Request

Watch a GitLab MR until CI is fully passing and Greptile has no unresolved actionable feedback. Fix issues yourself when they are small and clear; escalate to James when the request requires product judgment, architecture tradeoffs, or risky restructuring.

## Repository Mapping

| Repository | Path | Project ID | GitLab Path |
|------------|------|------------|-------------|
| MCP | `/Users/jbaldwin/repos/mcp` | `71810865` | `zapier/team-agents-platform/mcp` |
| AI Command Center | `/Users/jbaldwin/repos/ai-command-center` | `48901663` | `zapier/zapai/ai-command-center` |

If the MR URL or repo is unclear, ask James for the MR link.

## Workflow

### 1. Identify The MR

Use the MR URL from the previous step when available. Otherwise infer it from the current jj bookmark only if unambiguous; if not, ask James.

Gather:

- project id
- MR iid
- source branch/bookmark
- target branch
- current head SHA
- MR URL

Use Zapier MCP GitLab actions. Always inspect enabled Zapier actions before executing them in the active session; do not guess action names.

Useful GitLab API endpoints through raw request:

```text
GET /projects/<project_id>/merge_requests/<iid>
GET /projects/<project_id>/merge_requests/<iid>/pipelines?per_page=20
GET /projects/<project_id>/pipelines/<pipeline_id>/jobs?per_page=100
GET /projects/<project_id>/merge_requests/<iid>/discussions?per_page=100
POST /projects/<project_id>/merge_requests/<iid>/notes
PUT /projects/<project_id>/merge_requests/<iid>/discussions/<discussion_id>/notes/<note_id>
```

### 2. Poll CI Until Terminal

Check the latest pipeline for the MR head SHA. Treat CI as passing only when the latest relevant pipeline is `success` and there are no failed required jobs.

Statuses:

- `success`: move to Greptile review monitoring.
- `failed` or `canceled`: inspect failed jobs, fix if the failure is clear, then push a new jj commit.
- `created`, `pending`, `preparing`, `running`: wait and poll again.
- `skipped`, `manual`, or missing pipeline: report the state to James if it blocks confidence.

Polling guidance:

- Poll about every 60 seconds while jobs are active.
- If nothing changes for 20 minutes, give James a concise status instead of silently waiting forever.
- Do not declare success from an old pipeline after pushing fixes; verify the pipeline for the newest MR head SHA.

### 3. Handle CI Failures

When CI fails:

1. Fetch failed job names and logs.
2. Identify whether the failure is from this MR, flaky infrastructure, or unrelated trunk breakage.
3. If it is a clear MR issue, make the smallest correct fix.
4. Run the relevant local check first, then `pnpm types`, `pnpm lint`, and `pnpm fmt` when applicable.
5. Commit fixes with `jj describe` + `jj new`; never use `jj squash`.
6. Push the source bookmark to GitLab.
7. Poll the new pipeline.

If the failure needs secrets, external service access, production deployment, or a judgment call, stop and ask James.

### 4. Watch Greptile Reviews

Fetch MR discussions and notes. Greptile comments usually come from a bot or contain Greptile branding; identify them by author username/name and body text rather than assuming one exact account name.

Classify Greptile feedback:

- `actionable`: concrete bug, missed test, broken edge case, or clear maintainability improvement.
- `not-actionable`: vague style preference, incorrect reading of code, or suggestion that conflicts with repo conventions.
- `needs-james`: product behavior, architecture direction, security-sensitive decision, or broad rewrite.

For actionable feedback:

1. Read the relevant code before editing.
2. Make the smallest correct change.
3. Add or update tests when the feedback is about behavior.
4. Run targeted tests/checks, then the repo-required checks that fit the change.
5. Commit with `jj describe` + `jj new`.
6. Push the source bookmark.
7. Reply briefly on the Greptile thread with what changed, or explain why no code change was needed.

For non-actionable feedback, reply with concise evidence and do not make performative changes.

For anything needing James, stop with a short summary and the decision needed.

### 5. Ask Greptile For Another Review

After pushing fixes for Greptile feedback and after the new pipeline is at least started, post a new MR note:

```text
@greptile review
```

Then continue watching discussions. Do not spam Greptile: only request another review after you have pushed a new commit or materially answered all previous Greptile feedback.

### 6. Completion Criteria

Stop and report success only when all are true:

- The MR is open and points at the newest source bookmark commit.
- The latest MR pipeline for that commit is passing.
- Greptile has completed a review after the latest relevant fixes, or no Greptile review appears after a reasonable wait and James has been told.
- There are no unresolved actionable Greptile threads.
- Any remaining unresolved thread is clearly non-actionable or waiting on James.

Report:

```text
Babysit complete: <MR title> (!<iid>)
  CI: passing on <sha>
  Greptile: <clean / no actionable feedback / waiting on James>
  Fix commits pushed: <count and short messages>
  URL: <mr-url>
```

## Guardrails

- Do not merge the MR unless James explicitly asks in the current conversation.
- Do not deploy, rollback, alias production, or change production env vars.
- Do not force-push or rewrite published history unless James explicitly approves.
- Do not use `jj squash`. Follow-up fixes are new commits.
- Do not silently ignore failed CI or actionable Greptile feedback.
- Prefer minimal fixes over broad cleanup while babysitting.
