---
name: things-3
description: Manage James's Things 3 tasks and carry out the work they describe. Use when asked to inspect, organize, create, update, or execute Things to-dos, work through agent-tagged tasks, or resume work recorded in Things.
---

# Things 3

Things is James's task list and the handoff between agents. Do the requested work and leave enough context there for another agent to continue without asking James to repeat himself.

## Tools

Prefer scripting interfaces over driving an app's window. They are faster and more reliable.

- **Things**: use AppleScript (`osascript`, `application "Things3"`) for all reads and writes. AppleScript cannot reach checklist items; open the task in Things and use computer use only for those.
- **1Password**: use the `op` CLI. Keep passwords, codes, and recovery secrets out of Things notes and responses.
- **Everything else**: use a CLI or API when one exists. Use computer use for the browser and apps without one. James's browser is Helium or Arc, depending on the laptop; use whichever has his session.

## The agent tag

- The tag `agent` means James thinks an agent can handle all or part of the task, possibly with him. It grants no blanket autonomy; follow the current request and the task's notes.
- Work the scope James asks for. Do not expand one task into the whole queue.
- Keep the tag on blocked tasks. It says who may work on them, not whether they are ready.

## Doing the work

- Read the task's notes, dates, and project first, and treat Things as the current record. Check whether earlier work already covers the next step.
- Look up facts yourself; ask James only for decisions, permissions, or logins he must complete.
- The tag does not authorize purchases, payments, messages, or other commitments. When permission is missing, save the prepared next step and ask.
- Confirm the real outcome, such as an order confirmation or a sent message, before recording it. If a result is unclear, check history before retrying so nothing happens twice.

## Finishing and follow-ups

- Complete the task when its outcome is achieved. James wants to see work finished and new work created.
- If finishing creates a new obligation, make a separate follow-up with a concrete title rather than keeping the original open. For example, complete "Order smaller jacket" and create "Compare jacket sizes and return worse fit."
- If the outcome is still unmet, leave the task open with its next step or blocker.
- Before creating a follow-up, check for an existing one. Carry over the project and the `agent` tag when agent work continues. Set dates only when the evidence supports them: a start date for when to check back, a deadline for a real cutoff.

## Notes

Keep James's original instructions and links. Keep a short current-state note instead of appending session reports:

```text
2026-09-22: Requested courtesy credit for the four-person trip; response pending.
Ref: $41.95 trip, Sep 5. Email thread: [link]
Next: Check reply Sep 29; follow up in the same thread if unanswered.
```

The next agent should know what happened, what remains, and where to act. End the chat with a short summary of completed work, new follow-ups, and any decision James needs to make.
