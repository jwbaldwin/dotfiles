---
name: prototype
description: Build an isolated interactive prototype to answer an unresolved design question, either about a state model or competing UI approaches. Use when James asks to try an interaction, explore UI alternatives, or test whether a proposed behavior makes sense before implementation. For explaining an established system, use show-me instead.
---

# Prototype

Start with one explicit question and the observation that would help answer it. Infer the question from the conversation when clear; ask when choosing the wrong experiment would change the result.

## Choose the experiment

### State or logic

Use a small interactive demo with visible state, free-play controls, reset, and guided scenarios for the important transitions and edge cases. Prefer a shareable HTML file that runs without a server when that can faithfully represent the question. Use the real language/runtime or a local harness when browser JavaScript would hide the behavior being tested, such as database locking or time-zone rules.

### UI alternatives

Create a few structurally different approaches within the existing screen or routing convention. Make switching variants easy and keep the scenario and fixture data comparable. Variants should test different interactions or information layouts, not just colors and spacing.

Read the existing components and design tokens first. Call `html-artifacts` when producing HTML artifacts and use the relevant installed design skill for interaction or motion work.

## Isolate and build

- Use a temporary artifact for a standalone demo or the `workspace` skill for changes inside an application. Use jj bookmarks for retained repository experiments
- Clearly mark the result as a prototype. Keep state in memory or explicit disposable fixtures; a database experiment needs an isolated local database
- Keep app variants read-only with respect to real user data. Use fake actions when evaluating UI unless the agreed question requires local writes
- Build only enough to answer the question. Reuse existing primitives; defer production abstractions, broad error handling, and unrelated polish
- Show the relevant state after each action and make the experiment easy to restart and run

## Exercise and capture

Run the artifact yourself, exercise the proposed scenarios, and confirm it demonstrates the question rather than merely rendering. Note what the experiment cannot establish. Present the artifact and observations so James can judge the design.

Record the question, evidence, and verdict, including unresolved concerns. Distinguish observed behavior from a design choice James has not yet made. Retain useful runnable evidence in the agreed artifact location or on a prototype bookmark, with a pointer from the relevant local plan; update an external issue only when authorized.

The prototype is complete when it runs, the decisive scenarios have been exercised, and the result and remaining uncertainty are clear. Approval of a design is not approval to merge prototype code: production implementation follows the normal tests, review, and delivery workflow.

Adapted from [Matt Pocock's prototype](https://github.com/mattpocock/skills/tree/24fe0ef7737efae15c87225755e9f6f5965e4888/skills/engineering/prototype), under the [MIT license](LICENSE).
