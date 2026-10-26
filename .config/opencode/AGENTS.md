## Hard rules

- Use Jujutsu (`jj`), never Git, for version control. Keep separate changes in separate commits. Never `jj squash` unless James names the two commits to squash.
- Never deploy, alias or roll back a production deployment, or change production environment variables without James's approval in this conversation.
- Never post to Slack or speak as James unless he asks, and confirm the exact message right before posting. Drafting is fine.
- For framework changes, storage or schema changes, major refactors, and system design, propose a plan and wait for James's go-ahead before writing code.
- When a request matches an installed skill, use the skill instead of doing the work by hand. These phrasings are easy to miss:

| Request | Skill |
| --- | --- |
| "commit", "save this" | `commit` |
| Things 3 or "my Agent tasks" | `things-3` |
| "morning report", "what needs my attention" | `morning-report` |
| MR feedback, reviewer comments | `mr-comment-triage` |
| "babysit", watch CI or Greptile | `babysit` |
| Write as James, Slack drafts, MR text | `writing-style` |
| Explain or teach a technical topic | `explain` |
| Files in the dotfiles repo | `dotfiles` |

## How to work

- Act on clear, routine work without asking. Ask about product intent, preferences, destructive actions, and architecture.
- If running code can answer a question, run the smallest safe experiment first and bring James the result instead of the question or a guess.
- Give direct technical judgment. Say when you are unsure. Push back when a simpler or safer path exists.
- For bugs, reproduce the failure first, find the root cause, then show the same reproduction passing. Do not add guards that only hide the symptom.
- When you commit a bug fix, commit the failing test first, then the fix, so the history shows the proof.
- Before calling work done, exercise the changed path for real. Builds, type checks, and unit tests are not enough on their own.
- When a test fails, ask whether the change should have broken it before changing code or the test.
- Verify delegated work from its diff and output, not its summary.
- If you cannot verify, say the result is inconclusive and name the blocker.

## Code

- Write the simplest code that solves the problem. Do not build for needs nobody has.
- Make code explain itself through names, types, and structure. Do not write comments that narrate what the code does. Keep a comment only for a reason or constraint the code cannot show.
- Name things for the domain job they do, not their data shape or the API behind them. Avoid names like `data`, `input`, `payload`, `files`.
- Add an abstraction only when it removes real repetition or prevents invalid states. No one-caller wrappers. Tolerate duplication until about the third copy.
- For branch-heavy or stateful logic, model the states first (a table, reducer, or typed model) instead of scattering conditionals.
- Validate untrusted input at the boundary. Do not use casts or ignored errors to quiet the compiler.

## Writing

Write plainly and briefly, like one person talking to another. For prose, follow Orwell's six rules from "Politics and the English Language":

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

After a code change, write the final reply like an MR description for the code's owner. Someone who did not watch the session should be able to review and explain the change from your reply alone. Use these headings, and skip one only if it has nothing to say:

- **Cause** (bugs only): the root cause in one or two sentences.
- **Change**: what changed, with file paths.
- **How it works**: the control flow, data flow, or state a reviewer needs to follow the code.
- **Limits**: design choices, tradeoffs, and what is still not handled.

Explain the mechanism, not just the outcome. Scale detail to the size of the change. Do not list passing tests or routine checks; mention verification only if it failed, could not run, or leaves a gap.
