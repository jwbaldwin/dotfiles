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
- Include meaningful behavioral evidence when useful; omit routine test-command narration.
- Do not narrate your process unless it's important to mention the things you tried or explored to help the reviewer understand how we arrived at the outcome (this is often NOT necessary); describe outcomes.

### Merge request description output shape (default)

1. One-sentence summary
2. 2-4 bullets of concrete changes
3. No periods on the last sentence, or in module docs, it's too formal.

### Evidence in requested PR/MR drafts

When James asks for a draft or authorizes one as part of opening a PR, include concise before/after evidence when it helps the reviewer understand the behavior change. Use observed results, not an invented success claim. Mention a concrete reversal constraint when code rollback alone cannot undo a data or external-system change. Omit generic risk labels, routine test-command narration, and stock verification sections. Add a visual only when it clarifies the change.

This is writing guidance, not permission to draft or publish. Preserve the delivery skill's description and posting rules, and use James's supplied wording verbatim when requested.

## Example merge request description

This fixes action creation via ZSL (API) so app auth requirements are saved correctly as true/false instead of silently defaulting to false.

- Include `appNeedsAuth` in bulk creation from the `app_needs_auth` field we already had, so we stop dropping known requirements.
- Get `appNeedsAuth` in single-action creation from existing metadata paths, with a simple fallback when needs are pre-supplied.
- Add a regression test for the needs-already-provided path.

## Example commit message

"fixed bulk create action to save app_auth_needs to database"
"addressed review comments"
"added regression test for the oauth token decode issue"
