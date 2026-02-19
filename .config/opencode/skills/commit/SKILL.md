---
name: commit
description: Create a jj commit from current working copy changes with a well-written commit message. Triggered by "commit", "commit this", "commit changes", "jj commit", "save this", or after completing a task when James asks to commit the work.
---

# Commit

Create a jj commit from the current working copy changes. Write the commit message in James's preferred style.

## Commit Message Style

- All lowercase, no trailing period
- Plain language — no jargon, no abstract verbs (avoid "leverage", "facilitate", "persist", "derive")
- Short and concrete — say what changed, not how you feel about it
- One line is usually enough; only add detail if the "why" isn't obvious from context
- Do not narrate process — describe outcomes

### Good examples

```
fixed bulk create action to save app_auth_needs to database
addressed review comments
added regression test for the oauth token decode issue
refactor user authentication helpers
update dashboard widget to show monthly metrics
removed dead code from payment processor
```

### Bad examples

```
Update code  ← too vague
Fixed the issue where the authentication module was not correctly persisting  ← too wordy, jargon
feat: Add new dashboard component  ← conventional commits format, not our style
Refactored and improved the user service layer for better maintainability  ← buzzwords
```

## Workflow

### Step 1: Review changes

```bash
jj status
jj diff
```

Understand what changed. Read the diff carefully — the message should reflect the actual changes, not a guess.

### Step 2: Check context

Look at recent commit history for additional context:

```bash
jj log -r 'mine()' -n 10
```

This helps write a message that fits naturally with the surrounding history.

### Step 3: Write the message and commit

Based on the diff, write a commit message and describe it to James:

```bash
jj describe -m "the commit message here"
jj new
```

`jj describe` sets the message on the current change, and `jj new` creates a fresh empty working copy on top — this is the jj equivalent of git commit.

### Step 4: Verify

```bash
jj log -r 'mine()' -n 5
```

Confirm the commit landed correctly.

## Tips

- If changes span multiple unrelated concerns, suggest splitting first (see split-commits skill) rather than writing a vague umbrella message.
- When in doubt, ask James what the commit should say rather than guessing.
- Never use conventional commit prefixes (feat:, fix:, chore:, etc.) unless James explicitly asks for them.
