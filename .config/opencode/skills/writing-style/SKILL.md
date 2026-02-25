---
name: writing-style
description: Human-first writing style for comments, commit messages, merge request descriptions, review notes, and change summaries. Use when writing engineering communication that should be concise, concrete, and easy for teammates to scan quickly.
---

# Human First Writing Style

## Tone
Write for a busy teammate scanning in 10-15 seconds.

- Prefer concrete words and short verbs instead of technical jargon or "spec"-like language.
- Keep tone human, casual, and clear; avoid formal/spec language.
- Avoid caveat-heavy writing unless it changes a decision or introduces risk.
- Skip jargon and abstract verbs (`derive`, `persist`, `facilitate`, `leverage`) when a simpler word works.


## For a Merge Request Description
- Start with one to three plain sentence: what this fixes, where it shows up, and what bad behavior it replaces.
- Optimize for readability over defensive precision in summaries; reviewers can inspect code for details.
- Use a few short bullets to describe what the reviewer would see in this MR
- Each bullet must say: what changed + why it matters.
- Mention tests directly when present (especially regressions).
- Do not narrate your process unless it's important to mention the things you tried or explored to help the reviewer understand how we arrived at the outcome (this is often NOT necessary); describe outcomes.

### Merge request description output shape (default)

1. One-sentence summary
2. 2-4 bullets of concrete changes
3. No periods on the last sentence, or in module docs, it's too formal.

## Example merge request description

This fixes action creation via ZSL (API) so app auth requirements are saved correctly as true/false instead of silently defaulting to false.

- Include `appNeedsAuth` in bulk creation from the `app_needs_auth` field we already had, so we stop dropping known requirements.
- Get `appNeedsAuth` in single-action creation from existing metadata paths, with a simple fallback when needs are pre-supplied.
- Add a regression test for the needs-already-provided path.

## Example commit message

"fixed bulk create action to save app_auth_needs to database"
"addressed review comments"
"added regression test for the oauth token decode issue"
