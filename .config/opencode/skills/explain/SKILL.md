---
name: explain
description: Explain technical concepts from first principles in plain language. Start with a short mental model story, then define nouns and ground the story in step-by-step flows, diagrams, and concrete code references. Use when asked to explain, break down, ramp up, teach, simplify, or build deep understanding so the reader can explain and improve the system.
---

# Explain

## Purpose

Produce explanations that help a teammate internalize a system deeply enough to:

1. explain it clearly to someone else,
2. reason about trade-offs,
3. improve it safely.

Prioritize understanding over raw detail dumps.

## Language Style

Write clearly and directly.

- Use plain words.
- Avoid technical jargon when a simpler phrase works.
- Avoid spec-like or formal standards language unless the user asks for it or it's required.
- If you must use a technical term, define it immediately in one plain sentence.
- The use of similies or metaphors can help make abstract concepts more concrete, but avoid overusing them or mixing them.

## Default Explanation Workflow

Follow this sequence unless the user asks for a different shape.

1. Start with one short mental model story of how the system works end to end.
2. Define the nouns used in that story.
3. Walk through one or more step-by-step flows.
4. Ground each flow with concrete code references or snippets.
5. Explain why each major choice exists.
6. Summarize what was accomplished and what remains open (if this is a review of changes)
7. End with a short recap that matches the opening story.

## Output Shape

Use this structure for substantial explanations.

### 1) Mental Model Story

Start with a short, memorable story first.

- Keep it to 3-6 bullets.
- Use causal flow (A causes B causes C).
- Keep language plain.

### 2) Big Picture

State the core problem and the system's responsibilities in plain language.

### 3) Nouns

Define key terms before discussing interactions.

- Expand acronyms before using them.
- Keep each noun definition concrete and short.
- Clarify similarly named entities that are easy to confuse.

### 4) What / Why / How

For each major component or mechanism:

- `What`: what it is and what it does.
- `Why`: why it exists and what risk it prevents.
- `How`: how it works in this implementation.

### 5) Step-by-Step Flows

Present at least one end-to-end flow. Prefer 2-3 flows when useful.

- Use numbered steps.
- Include request/response examples for API-heavy systems.
- Call out failure paths and guards, not only happy path.

### 6) Diagrams

Use Mermaid diagrams when they materially improve understanding.

- Use `sequenceDiagram` for request lifecycles.
- Use `flowchart` for trust boundaries and component relationships.
- Keep diagrams compact: 3-7 participants/components.

### 7) Code Grounding

Anchor explanations in real code.

- Include file paths and short focused snippets.
- Explain why each snippet matters.
- Prefer critical lines over large blocks.
- Tie snippet behavior back to the noun and flow sections.

### 8) Synthesis

Close with:

- what changed or what the system now accomplishes,
- key risks or open questions,
- one short "teach-back" story that matches the opening mental model.

## Calibration Rules

If the user has not given style preferences, ask up to two targeted questions max:

1. required depth (primer, intermediate, advanced),
2. preferred shape (mental-model-first, nouns-first, code-first, or flow-first).

If the user already gave clear preferences, do not ask extra questions.

## Quality Bar

Ensure the explanation is:

- concrete,
- causally accurate,
- easy to scan,
- technically grounded,
- reusable for onboarding.

## Avoid

- Starting with implementation details before defining terms.
- Dumping long logs, raw diffs, or MR text without synthesis.
- Using vague claims like "this improves reliability" without naming the failure mode.
- Hiding important trade-offs or unresolved risks.
- Dense jargon or spec-like prose when plain language would be clearer.

## Reusable Ending Template

Use a concise ending in this shape:

1. "If you remember one story, remember this..."
2. 3-6 bullets that narrate identity -> validation -> state change -> outcome.
