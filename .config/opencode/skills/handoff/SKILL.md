---
name: handoff
description: Create Amp-style handoff prompts for continuing work in a fresh session. Use when James asks to "handoff", "split this into handoffs", "prepare a next-session prompt", break a large planning run into smaller executable chunks, or turn a rough working prototype into reviewable cleanup and improvement passes.
---

# Handoff

Create a focused fresh-session prompt from the current thread. Treat handoff as extraction, not compaction: keep what the next session needs to act, and drop the conversational noise.

This is a skill, not a plugin. Do not pretend you can open a new session, preload files, or expose transcript tools. Produce ready-to-paste handoff text and tell James to start a fresh session with it.

## Core Rules

- Do not continue the work inside the handoff unless James explicitly asks for both the handoff and the implementation.
- Use James's stated follow-up goal to shape the handoff. If he does not give one, infer the most natural next step from the thread.
- Be generous with file references. Missing one important file is worse than including a few extras.
- Preserve decisions, constraints, user preferences, technical patterns, known risks, and validation steps.
- Exclude dead ends, failed experiments unless they are important warnings, and back-and-forth chatter.
- Prefer focused threads. If the work is broad, split it into multiple handoffs instead of writing one vague umbrella prompt.

## Workflow

1. Decide the handoff shape.
   - Use a single handoff for one clear next task.
   - Use a split handoff set for 2-6 parallel or sequential chunks.
   - Use prototype cleanup handoffs when a working solution needs tests, hardening, refactors, or polish.
2. Gather only the context needed to name the work accurately.
   - Reuse the current thread first.
   - Read code or diffs only when needed to identify the right files, seams, or constraints.
   - Do not start implementing the next task.
3. Choose relevant files.
   - Target roughly 8-15 files for a normal handoff, up to 20 for complex work.
   - Include files likely to be edited, nearby dependencies, tests, configs, and key reference docs.
   - Put `@file` references near the top of the generated prompt so the next session can load them immediately.
4. Draft the prompt.
   - State the goal in one concrete sentence.
   - Summarize the current state and the decisions already made.
   - Spell out constraints, preferences, and anything that must not change.
   - Give a short ordered task list when sequence matters.
   - Include validation commands or review steps.
   - Name what is out of scope when that boundary matters.
5. Sanity-check the result.
   - Make sure the prompt is actionable without reading the whole old thread.
   - Make sure it does not smuggle in unverified claims.
   - Make sure it stays narrow enough for a fresh focused session.

## Chunking Heuristics

### Large Planning Runs

- Split by deliverable, boundary, or dependency chain, not by arbitrary file count.
- Give each chunk a concrete finish line such as "ship the API route", "write characterization tests", or "refactor auth helpers without behavior changes".
- Keep chunks reviewable. A reviewer should be able to understand why the work belongs together.
- If one chunk depends on another, say so explicitly and order them.

### Sloppy Prototype Cleanup

- Preserve working behavior unless James explicitly wants behavior changes.
- Prefer seams like tests, types, API contracts, storage boundaries, or isolated modules.
- Usually split in this order: lock behavior with tests, isolate interfaces, simplify internals, then polish naming/docs.
- Avoid handoffs like "clean up the prototype". Replace them with precise prompts that name the behavior to preserve and the code area to improve.

## Output

When James wants one handoff, return:

1. A one-line note about what the handoff is for.
2. A short `Files:` line if that helps scanning.
3. A fenced text block containing the exact prompt to paste into the fresh session.

When James wants multiple handoffs, return:

- A short overview of how you split the work.
- Numbered handoffs.
- For each handoff: title, why this chunk exists, and a fenced text block with the ready-to-paste prompt.

Use the patterns in `references/templates.md` when you need examples or a default structure.
