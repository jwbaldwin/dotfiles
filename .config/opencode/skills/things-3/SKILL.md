---
name: things-3
description: Manage James's Things 3 tasks and carry out the work they describe using computer use. Use when asked to inspect, organize, create, update, or execute Things to-dos, work through Agent-tagged tasks, or resume work recorded in Things.
---

# Things 3

Things is James's task list and the durable handoff between agents. Do the requested work and leave enough context there for another agent to continue without asking James to repeat himself.

## Scope and the Agent tag

- The exact tag is `Agent`. It means James thinks an agent can handle all or part of the task, possibly in collaboration with him.
- The tag grants no blanket autonomy. Tagged tasks may need collaboration; untagged tasks may be explicitly assigned for fully autonomous work. Follow the current request and the task's instructions.
- When asked for Agent tasks, find the tag and read the matching tasks. When asked for a specific task or another list, search that scope regardless of tags. Do not silently expand the assignment to the whole queue.
- Keep `Agent` on blocked tasks. It describes who may work on them, not whether they are ready. Do not invent a waiting tag or remove it when James must decide.
- Read the title, notes, checklist, dates, and project context before acting. Check whether prior work or another agent already covers the next step. Use Things as the current record rather than stale conversation summaries.

## Computer use first

Use computer use for Things, the browser, and 1Password. James uses **Helium or Arc**, depending on the laptop; discover which is available and use the appropriate personal browser/profile. Do not assume Helium is always installed or start a separate browser that lacks his session.

Read [computer-use.md](references/computer-use.md) for the tool sequence and app-editing mechanics. Use available tools rather than assuming a browser connection, WebMCP, or Chromium integration exists. Those may be options later; they are not prerequisites. If computer use is unavailable, report the specific blocker and propose an available fallback rather than silently replacing the workflow with scripts or direct database access.

## Carry out the task

1. Identify the requested outcome, constraints, and any recorded next action. Research, collaboration, and execution are distinct requests; preserve the requested scope.
2. Start clear work within that scope. Ask only for decisions or permissions that materially affect the result; look up facts in the available apps first.
3. Use the personal browser and 1Password as needed. Let James unlock 1Password or complete authentication when required. Keep passwords, verification codes, and recovery secrets out of Things notes and responses.
4. The task's tag does not authorize purchases, payments, messages, or other commitments. Follow the current request and applicable confirmation rules. When permission or a choice is missing, save the prepared next step and ask a focused question.
5. Check the real outcome in the relevant app: an order confirmation, a sent message, an updated account, or another concrete result. If an action's result is uncertain, inspect its history before retrying to avoid duplicate orders or messages.
6. Save progress to Things after meaningful actions and before stopping. A draft is not sent; a recommendation is not a purchase; a submitted request is not an approved outcome.

## Finish work and create follow-ups

- Mark the original task complete when its requested outcome is achieved. James wants to see work completed and new work created.
- If completion creates a new obligation, create a separately named follow-up rather than keeping the original alive or renaming it into a different task. For example, complete “Order smaller jacket” after ordering and create “Compare jacket sizes and return worse fit.”
- If the original outcome is still unmet, keep it open with its next action or blocker. A partial step does not finish a broader task.
- Before creating a follow-up, check for an existing equivalent. Carry over the relevant project and `Agent` tag when agent involvement continues; do not automatically tag work meant only for James.
- Use a concrete action title. Copy the minimum context needed into the follow-up and link the original task when useful. Do not make the next agent chase an entire chat transcript.
- Set follow-up dates when the task or evidence supports them. Use a reminder/start date for when to check back and a deadline for a real cutoff; do not invent urgency. Preserve existing dates unless the work calls for a change.
- Reopen or inspect edited tasks to confirm the notes, dates, tags, checklist, and completion state actually saved.

## Short, sufficient handoffs

Preserve James's original instructions and useful links. Maintain a compact current-state note rather than appending verbose session reports. Keep important completed actions and decisions; remove repetition from agent-authored updates.

Use only the fields needed, usually a few short lines:

```text
2026-09-22: Requested courtesy credit for the four-person trip; response pending.
Ref: $41.95 trip, Sep 5. Email thread: [link]
Next: Check reply Sep 29; follow up in the same thread if unanswered.
```

For blocked work, name the exact decision and the prepared next action. For a recommendation, record the chosen option, key constraint, link, and whether James approved it. Include order/reference IDs when needed to resume, but no unnecessary personal or account details.

The next agent should know **what happened, what remains, and where to act**. Do not force a template onto a task that needs only one sentence.

End the chat with a short summary of completed work, created follow-ups, and any decision James needs to make. Keep the durable detail in Things.
