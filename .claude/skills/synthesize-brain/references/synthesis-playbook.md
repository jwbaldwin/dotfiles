# Synthesis Playbook

Use this playbook after proposing candidate sessions and exporting corpus.

## 0) Candidate-First Selection

Start with a ranked shortlist before synthesis unless James gives explicit `ses_...` IDs.

- Use prompt relevance + directive density + recency to rank candidates.
- Show 3-6 candidates with a short reason for each.
- Confirm final selection with one focused question.
- If James says "just pick", auto-select top N and proceed.

## 1) Signal Taxonomy

Classify each candidate signal into one primary category:

- Collaboration contract
- Engineering principles
- Technical stack preferences
- Code quality standards
- Design taste and UX preferences
- Delivery workflow preferences
- Anti-patterns and hard no-go items

## 2) Confidence Rules

Treat confidence as high only when one of these is true:

- James states an explicit hard constraint (`must`, `never`, `always`).
- The same preference appears in at least two sessions.
- A preference is repeated with the same intent over time.

Treat confidence as provisional when:

- It appears once with weak wording.
- It is tied to a one-off tactical situation.
- It conflicts with newer sessions.

## 3) Placement Rules

- Put hard guardrails into `AGENTS.md`.
- Put detailed principles, rationale, and evidence into `BRAIN.md`.
- Put location-specific guidance into local `AGENTS.md` only when tied to a clear directory boundary.

## 4) Evidence Format

Use compact evidence tags with every synthesized principle:

- `Source: ses_xxx - "short quote"`

When there are multiple sources, list the strongest two or three.

## 5) Conflict Resolution

- Prefer newer explicit instructions over older ones.
- If conflict remains unresolved, keep both in `BRAIN.md` under a conflict note.
- Do not place unresolved conflicts in hard guardrails.

## 6) Suggested Output Shape

`AGENTS.md` (concise):

- `## James Brain Synthesis`
- 6-12 high-confidence bullets max

`BRAIN.md` (detailed):

- `## Core Principles`
- `## Engineering Guidance`
- `## Design and Taste`
- `## Workflow Preferences`
- `## Anti-Patterns`
- `## Evidence Index`
- `## Open Conflicts`
