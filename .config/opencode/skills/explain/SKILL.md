---
name: explain
description: Explain a technical code change, algorithm, architecture, bug, or concept from first principles in James's concise learning style. Use when the user explicitly asks to understand, learn, or have a technical subject explained. Do not trigger for routine answers, implementation work, summaries, reviews, or generic requests to simplify code.
---

# Explain

## Goal

Help the user understand the whole relevant idea well enough to reason about it, question it, and own it. Keep the explanation tight enough to read in one sitting.

Complete does not mean exhaustive. Cover what matters to the user's question and omit detail that does not change their understanding.

## Default Style

- Start from first principles: state the problem, then build the idea from facts the user can verify.
- Answer the exact question before adding context.
- Explain causes and consequences, not just parts and labels.
- Use plain, concrete language. Define necessary technical terms inline.
- Prefer one strong example over several weak ones.
- Use real code, values, names, and paths when available.
- Skip the preamble, throat-clearing, and repeated conclusions.
- Do not praise the question or announce the explanation plan.

## Length

Produce a one-page explanation by default.

- Aim for fewer than 100 lines of prose.
- Never exceed 150 lines of prose unless the user explicitly asks for a deep dive.
- Diagrams and other visuals do not count toward the prose limit.
- Gain brevity through clearer structure, visuals, and removing repetition. Do not hide a critical assumption, trade-off, or risk merely to meet the limit.
- If useful detail will not fit, give the complete core explanation first, then offer specific follow-up topics instead of continuing automatically.

## Choose the Shape to Fit the Subject

Do not force every explanation into the same sections. Choose the smallest structure that fully answers the question.

Examples of useful shapes, not required templates:

- **Code change:** problem → reason for the change → new behavior → important trade-offs → how to own it
- **Algorithm:** intuition → invariant → walkthrough → why it works → complexity
- **Architecture:** purpose → responsibilities → boundaries → interactions → trade-offs
- **Bug:** symptom → root cause → triggering conditions → fix → remaining risk
- **Technical concept:** mental model → mechanics → concrete example → implications

Use only the parts relevant to the subject. Reliability, maintenance, failure handling, complexity, history, and alternatives belong only when they help answer the actual question.

## Visuals

Use a compact diagram, pseudocode, call tree, file tree, diff, table, or short snippet when it replaces prose or makes order and ownership clearer. Follow the `show-me` skill when a visual would materially improve the explanation.

Place each visual beside the point it supports. Do not restate the whole visual in prose.

## Code Grounding

When explaining real code:

- Inspect the implementation instead of guessing.
- Cite only the load-bearing files and symbols.
- Show focused snippets only when the exact code matters.
- Explain what a snippet proves; do not narrate it line by line.
- Distinguish verified behavior from inference or uncertainty.

## Depth and Questions

Infer the appropriate shape and depth from the request. Ask a clarifying question only when ambiguity would materially change the explanation. Do not ask the user to choose an explanation format by default.

Before finishing, silently check that the user can answer:

1. What is this?
2. Why does it exist or work this way?
3. How does the important part work?
4. What should I remember or question?

Adapt these checks to the topic; do not print them as a standard section.

## Ending

End once the question is answered. If a recap helps, use one short recap of no more than three bullets. Do not repeat the opening explanation as a separate teach-back story.
