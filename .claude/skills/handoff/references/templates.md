# Handoff Templates

Use these patterns when the thread needs a clean, focused continuation. Adapt the wording to the task instead of filling them mechanically.

## Single Handoff Template

```text
@path/one @path/two @path/three

Goal: <one concrete next-session goal>

Context:
- <what already exists>
- <important decision or constraint>
- <important decision or constraint>

What to do:
1. <first concrete step>
2. <second concrete step>
3. <validation or review step>

Important constraints:
- <behavior that must not change>
- <style, architecture, or scope boundary>

Validation:
- <command>
- <command>

Out of scope:
- <anything the next session should avoid>
```

## Split Handoff Template

Use this when one thread needs to become multiple smaller threads or agent tasks.

```text
Handoff <N>: <short title>

Why this chunk exists:
- <single responsibility for this chunk>
- <dependency or sequencing note if needed>

Prompt:
@path/one @path/two

Goal: <clear outcome>

Context:
- <only the facts needed for this chunk>

What to do:
1. <step>
2. <step>

Validation:
- <command or manual check>

Out of scope:
- <neighboring work owned by another chunk>
```

## Prototype Cleanup Checklist

When splitting a rough but working prototype, prefer chunks like these:

1. Characterization tests that lock in the current behavior.
2. Interface cleanup at module or API boundaries.
3. Internal refactors that reduce complexity without changing outputs.
4. Error handling, typing, and edge-case hardening.
5. Naming, docs, and follow-up polish.

Do not mix all of those into one vague handoff unless the code area is tiny.

## Good Handoff Traits

- Starts with the exact goal.
- Includes enough `@file` references to avoid another archaeology pass.
- Carries forward decisions already made.
- Names the validation path.
- Stays narrow enough for one focused session.

## Bad Handoff Traits

- Reads like a transcript summary.
- Omits the files that matter.
- Asks the next session to "figure out the rest".
- Mixes multiple unrelated outcomes into one prompt.
- Leaves behavior-preservation assumptions implicit.
