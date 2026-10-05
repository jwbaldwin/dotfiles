---
name: retro
description: Review a coding session and propose evidence-backed improvements to the agent's checks, navigation, tooling, and instructions. Use when James asks for a retrospective, reviews what went wrong in a session, or asks how to prevent repeated agent mistakes. This reviews the working environment rather than auditing application architecture.
---

# Session Retrospective

Find the smallest environment changes that would improve the next run. Default to the current session; use the sessions James names when he specifies others.

## Gather evidence

- Read the actual conversation, relevant tool results, and resulting artifacts. For past sessions, use available history tools or the installed agent's supported export command; inspect its documentation before guessing storage paths or database schemas
- If the session cannot be retrieved, state the missing evidence and ask for the session or export rather than inventing a retrospective from a final summary
- Trace each candidate to a concrete event: a repeated search, wrong assumption, failed check, missed constraint, expensive tool call, or unavailable observation
- Separate observed mistakes from untested explanations. Do not turn a one-off task request into a global preference

## Find improvements

Consider only categories supported by the session:

- **Checks:** inspect the repository's existing test, lint, typecheck, and CI commands first. Repair an unwired or broken check before proposing another. Mechanical mistakes should lead to an executable check when its cost is justified
- **Navigation:** point to information that was difficult to discover, with a clear condition for reading it. Avoid copying facts that a cheap authoritative lookup already provides
- **Tooling and information:** improve access to the particular logs, artifacts, or read-only observations the investigation needed; reduce repeated or needlessly large tool calls
- **Instructions:** clarify conflicting or ineffective guidance. Keep judgment-based standards available to both implementation and review. Keep a concept's rules and exceptions together and give workflows observable finish lines

Prefer one authoritative instruction over repeated rules across files. Before deleting a rule as ineffective, look for evidence that the behavior is already enforced elsewhere or compare runs with and without it. Brevity alone does not justify removing a constraint.

## Propose the smallest fix

For each worthwhile finding, give:

1. The session evidence and its practical consequence
2. The exact check, tool, or document to change
3. How the change would prevent or expose the problem
4. A concrete way to test that claim

Order findings by impact. Include only proposals supported by evidence; no fixed count is required. The retrospective is complete when each proposal has a traceable failure, a specific intervention, and a way to tell whether it works.

Present recommendations first. A retrospective alone does not authorize editing global instructions or application code. When James asks to apply a finding, make the focused change and exercise its behavior: for a new check, show the relevant bad case fails and the corrected case passes. Preserve unrelated work and use the existing delivery skills when requested.

Adapted from [Matt Pocock's retro](https://github.com/mattpocock/skills/tree/24fe0ef7737efae15c87225755e9f6f5965e4888/skills/engineering/retro), under the [MIT license](LICENSE).
