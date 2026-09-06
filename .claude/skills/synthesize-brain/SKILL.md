---
name: synthesize-brain
description: Suggest and select high-value past OpenCode sessions, extract James's durable preferences and principles, and synthesize them into AGENTS.md plus focused brain docs in the active repository. Use when James says things like "synthesize my brain", "use the last N sessions", "high-value conversations", or "distill my preferences/taste/guidance".
---

# Synthesize Brain

Run this skill as a one-shot agent workflow. James should not need to run scripts manually.

## Interaction Contract

1. Start by proposing top candidate sessions.
2. Confirm the final session set with James (unless he gave explicit session IDs).
3. Synthesize high-signal guidance into repo guardrails.
4. Report what changed and why.

## Required Workflow

1. Parse scope from James's prompt.

   - If explicit `ses_...` IDs are present, use those directly.
   - If James says "last N sessions", treat N as the selection count.
   - If James says "high-value conversations" without IDs, run candidate ranking first.

2. Suggest top candidates from history.

   Run (agent-internal):

   ```bash
   python3 ~/.config/opencode/skills/synthesize-brain/scripts/export_session_corpus.py \
     --suggest 6 \
     --recent-window 60 \
     --query "<original user prompt>" \
     --directory "<active repo absolute path>" \
     --format markdown \
     --output /tmp/brain-session-candidates.md
   ```

   Show a short shortlist (3-6) with ID, title, date, and reason.

3. Confirm final selection.

   - Ask one targeted selection question if IDs were not explicit.
   - If James says "just pick", auto-select top N.

4. Export corpus for selected sessions.

   Run with explicit IDs:

   ```bash
   python3 ~/.config/opencode/skills/synthesize-brain/scripts/export_session_corpus.py \
     --session-id ses_a \
     --session-id ses_b \
     --format markdown \
     --output /tmp/brain-corpus.md
   ```

   Or auto-select N:

   ```bash
   python3 ~/.config/opencode/skills/synthesize-brain/scripts/export_session_corpus.py \
     --auto-select 3 \
     --query "<original user prompt>" \
     --directory "<active repo absolute path>" \
     --format markdown \
     --output /tmp/brain-corpus.md
   ```

5. Extract and classify durable principles.

   - Use `references/synthesis-playbook.md`.
   - Keep only durable guidance (explicit constraints or repeated preferences).
   - Add evidence tags for each principle: `Source: ses_xxx - "quote"`.

6. Synthesize into the active repository.

   - Update `AGENTS.md` with concise hard guardrails only.
   - Create/update `BRAIN.md` with richer principles, rationale, and evidence.
   - Add local `AGENTS.md` only when guidance is clearly directory-specific.

7. Return a synthesis report.

   - Sessions used.
   - Files updated/created.
   - Top distilled principles with evidence.
   - Conflicts or provisional items.

## Quality Gates

- Never invent preferences not grounded in corpus evidence.
- Prefer recent explicit instructions when sources conflict.
- Keep `AGENTS.md` short; move detail into `BRAIN.md`.
- Mark uncertain rules as provisional and keep them out of hard guardrails.

## Anti-Patterns

- Forcing James to run scripts manually.
- Dumping raw transcripts into repo docs.
- Treating one-off tactical asks as global principles.
- Rewriting entire docs when additive edits are sufficient.
