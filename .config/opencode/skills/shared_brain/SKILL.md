---
name: shared-brain
description: Use shared brain context from any repo. Trigger with "use shared brain", "consult the brain", or "consult brain".
license: MIT
allowed-tools:
  - read
  - glob
  - grep
metadata:
  version: "1.0"
---

# Shared Brain Context

Use this skill when <USER> asks to use context from shared brain while working in another repository.

## Source Location

Base directory for this skill: /Users/jbaldwin/repos/projects/shared_brain
Relative paths in this skill (e.g. scripts/, reference/) are relative to this base directory.
Note: file list is sampled.

## Required Workflow

1. Search across all folders in shared brain, including `private/` folders when present and readable.
2. Prefer targeted search (`grep`) and focused reads over broad dumping.
3. Prefer fresh sources and recent additions.
4. Synthesize findings and cite exact file paths used.

## Freshness and Staleness Rules

- Prefer newer notes using the date prefix format `YYYY-MM-DD-...`.
- When sources conflict, weight newer sources higher and call out the conflict.
- Explicitly flag information that may be stale, superseded, irrelevant, or uncertain.
- If recency is unclear, state uncertainty and surface both likely-current and older context.

## Constraints

- Do not write or modify shared-brain files unless James explicitly asks.
- If a requested path cannot be read, report the exact path and continue with available sources.

