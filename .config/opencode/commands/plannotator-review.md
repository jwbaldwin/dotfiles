---
description: Open interactive code review for current changes or a PR URL
---

## Code Review Feedback

Run Plannotator review through Git diff mode. This command must always include
`--git`; do not run bare `plannotator review` in a JJ workspace. Plannotator's
native JJ diff path can emit hunk metadata that crashes the browser diff
renderer with `Expected node, not`.

```bash
/Users/jbaldwin/.local/bin/plannotator review --git $ARGUMENTS
```

If there are no slash-command arguments, run the same command without a trailing
argument. If there is a PR URL or other argument, append it after `--git`.

Do not use the native JJ diff path, even if the current repository uses JJ.

## Your task

If the review returns feedback or annotations, address them. If no changes were
requested, acknowledge and continue.
=======
description: Open interactive code review for current changes
---

The Plannotator Code Review has been triggered. Opening the review UI...
Acknowledge "Opening code review..." and wait for the user's feedback.
