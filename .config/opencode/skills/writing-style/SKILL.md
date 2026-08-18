---
name: writing-style
description: Human-first writing style for comments, reviews, merge requests, commits, team updates, and general engineering writing. Use when writing engineering communication that should be concise, concrete, and easy for teammates to scan quickly
---

# Human First Writing Style

Write like a teammate thinking clearly who is writing for another busy teammate who will scan the content quickly

## Voice

Stop using jargon and speak coherently. State the thing more simply and concisely, like one human talking to another

- Keep tone human, casual, and clear; avoid formal/spec language
- Lead with the answer, change, concern, or decision
- Use plain words and short verbs. Keep technical terms only when they are the clearest words
  - Prefer concrete words and short verbs instead of technical jargon or "spec"-like language
- Avoid caveat-heavy writing unless it changes a decision or introduces risk
- Don't ever use abstract verbs (`derive`, `persist`, `facilitate`, `leverage`) when a simpler word works
- If discussing code/technical items: name the exact code, behavior, or choice and its concrete consequence
- State uncertainty only when it is real: “I think,” “am I reading this right?”, or “could this…?” Do not weaken confirmed facts with automatic hedging
- Be direct, not cold. Brief, specific praise or humor is welcome when it fits
- Avoid formal filler, em dashes, dramatic claims, and abstract wording. Do not fake typos, slang, emoji, or profanity to sound human
- In general, avoid all LLM-slopisms and write like James would
- Avoid trailing periods

## For a Merge Request Description

- Start with one or two sentences saying what changed and why it matters. Add only useful detail: behavior changes, reviewer-visible choices, rollout, or risks. A tiny MR may need one sentence; a risky one may need something more
- Describe outcomes, not the agent's process, unless the investigation explains an important decision
- Optimize for readability over "precision"; reviewers can inspect code for details
- Each bullet must say: what changed + why it matters
- Do not narrate your process unless it's important to mention the things you tried or explored to help the reviewer understand how we arrived at the outcome (this is often NOT necessary); describe outcomes
- Never mention that you ran the test, lint, etc. That's useless and assumed. It's noise. We hate noise

### Merge request description output shape (default)

1. One-sentence summary
2. 1-2 bullets of concrete changes for small - medium MRs, 2-4 bullets for larger MRs
    - Only add a bullet if it describes a meaningful change that reviewers should know about
3. **No periods on the last sentence**, or in module docs, it's too formal

## Writing a commit message

 - Use a short, concrete summary; lowercase. For review follow-ups, say what changed
"fixed bulk create action to save app_auth_needs to database"
"addressed review comments"
"added regression test for the oauth token decode issue"

## Drafting a review comment
- Use this shape: observation → consequence → smallest useful fix or direct question
- Give a concrete alternative when disagreeing
- Keep simple nits to one line, mark optional feedback, and use an example when it makes the issue obvious

