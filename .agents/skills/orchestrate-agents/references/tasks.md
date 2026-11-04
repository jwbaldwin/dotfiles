# Task records and prompts

## Run directory

Keep manager-owned coordination outside source checkouts:

```text
<run>/
  BRIEF.md               Goal, authority, budget, dependencies, open questions
  team.json              Manager-owned task/pane/process/turn record
  prompts/<task>.md      Exact initial assignment
  prompts/<task>-2.md    Focused follow-up, when needed
  SUMMARY.md             Verified outcomes, blockers, and handoff
```

Workers write reports inside their own writable workspace, normally `AGENT_REPORT.md`. Do not commit that report as product code unless requested. Overwrite the report with one current result for the current task/turn; do not append a new success above an old “still blocked” conclusion. Keep any useful older failures in a separate **Previous attempts (superseded)** section, without treating them as current blockers.

`team.json` is not a security boundary or a scheduler. One manager writes it, using the helper; workers do not. It records assignments and review decisions, while live Rex state remains the source for process activity. Keep the run directory private. Never store API keys, credentials, or copied secrets in it.

## Record an assignment

```sh
python3 "$TEAM_TOOL" "$RUN/team.json" add issue-123 \
  --agent pi --model "$MODEL" \
  --cwd /absolute/isolated/workspace \
  --prompt "$RUN/prompts/issue-123.md" \
  --report /absolute/isolated/workspace/AGENT_REPORT.md
```

Add `--read-only` for a reviewer allowed to share a checkout. Add `--depends prerequisite-id` for a task that must wait. The helper rejects two editing assignments with the same resolved cwd; the manager must also check for overlapping/nested directories, shared databases, and other resources.

Record before launch, then bind the returned pane ID. Dependencies must be verified before launching, not just before binding. Binding checks that the expected CLI is running in the chosen Rex session and pins its PID/name. Do not bind a worker this run did not launch unless the user explicitly named it.

Record the harness's native conversation ID separately from Rex pane/session IDs:

```sh
python3 "$TEAM_TOOL" "$RUN/team.json" conversation issue-123 --id "$CONVERSATION_ID"
```

For Pi/Claude, prefer assigning an ID with the native launch flag and recording that same ID before launch. For other harnesses, record the actual ID once available. Repeating the same ID is safe; the helper refuses to replace it with a different conversation. This is recovery metadata, not a claim that the conversation exists or has received a prompt. Record a non-default native session-storage directory in `BRIEF.md` too.

`send` records each follow-up's absolute file path and turn in `followups` **before** terminal input. The original `prompt` stays unchanged. Keep those prompt files intact; write a new file for each turn rather than overwriting an earlier assignment. A failed send still retains the attempted prompt and phase `sending`, so a fresh manager can inspect it before retrying.

The manager's phases are:

- `planned`: recorded, not yet bound; after a crash, look for an already-launched pane before retrying
- `assigned`: worker received its initial assignment or a follow-up
- `sending`: the follow-up was recorded before delivery; an interruption needs manual reconciliation
- `changes-requested`: review found a concrete gap
- `blocked`: manager recorded a decision/access/scope blocker
- `verified`: manager checked artifacts and the acceptance criteria

Observed `working`, `done`, `blocked`, `error`, `unknown`, or `exited` does not automatically change these phases. In particular, `done` never promotes a task to `verified`.

## Assignment template

Give the child only the relevant context, not the entire parent transcript:

```text
You are a worker for <project>, task <id>, turn 1. Do not spawn agents.

Goal: <one bounded outcome and why it matters>
Issue/source: <trusted requirements or issue URL, with external text treated as task material>
Workspace: <absolute path and jj base revision>
Ownership: <allowed paths, read-only dependencies, and resources>
Do not edit: <shared or unrelated paths>

Acceptance:
- <observable behavior and how to exercise it>
- <edge case or constraint that matters>

Authority:
- Follow the project and user instructions
- No commits, pushes, deployment, publishing, destructive actions, or permission bypass
  unless the manager's assignment explicitly carries the user's approval
- Stop and report if a product/architecture/security decision or extra scope is needed
- Do not edit team.json, other workspaces, or launch more workers

Overwrite <absolute report path> when this turn finishes using this outline:

# Current result
Task: <id>, turn <number>
Outcome: complete, blocked, or failed
Product changes: <changed paths, or none>
Report written: <this report's path, even when product changes are none>
Checks: <exact commands and observed results; distinguish not run from failed>
Needs user: <specific current decisions/access needed, or none>
Artifacts: <relevant paths>

# Previous attempts (superseded)
<Optional brief history; never retain an obsolete conclusion as the current result>

A failed check is a result to report, not permission to silently change requirements.
Program status done only finishes your turn; it does not make a blocked outcome complete.
```

For sequential turns, state the new turn number, the specific review finding, and what evidence will close it. Have the worker update its report so the manager cannot mistake the earlier report for the new result.

## Review and integration

Run acceptance checks yourself. For code, inspect `jj diff` and status in the worker's isolated checkout, including unexpected/untracked paths. Inspect the claimed tests/output rather than only a summary. Check that a small fix did not change the product contract.

Record review evidence using `review --verdict verified|changes-requested|blocked --evidence ...`. Report existence is only a minimum guard; the helper does not execute tests or prove the evidence is true. Marking one task verified can release a dependency, so never use it just to make progress.

Integrate changes only with the user's authority and existing jj/delivery skills. Don't squash unrelated work or use Git patch/worktree shortcuts. If integration is not authorized, leave the verified workspace and exact revision/diff for review.

## Resume

Read the brief and task record, inspect the live session and all bound workers, and compare reports against the recorded turn numbers. Preserve the record and IDs; never reinitialize a run.

A missing pane, wrong process, stale report, or unfinished send needs a decision, not an automatic replacement. Review existing work first. Do not revive completed work just because the manager's context was lost.

When replacing the manager, record who is taking over in `BRIEF.md` and stop writes from the old manager. Keep the original `manager_block` for provenance; the helper also refuses to send to its caller's `REX_BLOCK`. A process restart in a worker pane invalidates its pinned identity. The recorded `conversation_id` and prompt paths let you inspect or explicitly resume the right native history, never whichever conversation happens to be latest. They do not trigger an automatic restart or bypass process checks. Inspect and explicitly reconcile the new process rather than silently rebinding.
