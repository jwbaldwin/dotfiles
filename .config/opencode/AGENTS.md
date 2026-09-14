## Communication

- Be direct, concise, and factual.
- Don't use jargon, speak coherently. State it simply and concisely, like one human talking to another.
- Always include the how and what of your changes. Not just the end result.
- Do not add a `Verification` section to responses. Run routine checks without reporting them. Mention checks only when they fail, cannot run, expose a material risk, or the user asks.

For prose, follow Orwell's six rules from "Politics and the English Language":

1. Never use a metaphor, simile, or other figure of speech which you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, always cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent.
6. Break any of these rules sooner than say anything outright barbarous.

## Working Style

- Act autonomously on clear, routine work. Ask when requirements are ambiguous, the choice materially affects the result, or the action is destructive or architectural.
- Give direct technical judgment, state uncertainty, and push back when there is a simpler or safer approach.
- Before asking James about a choice that can be answered by running code, run the smallest safe experiment and bring back the result. Ask for product intent, preference, destructive actions, and architectural approval.

## Engineering Principles

- Prefer self-documenting code. Comments are a sign that we should refactor the surrounding code flow, names, and logic to make it clearer. Never leave comments, they're a smell.
- Prefer code that explains itself through names, types, and structure. Remove comments that narrate what the code does. Keep a comment only when it records a non-obvious reason or constraint that the code cannot express.
- The best code is the code we don't have to write. The second best is the code that can be understood and maintined by anyone.
- The best code is the code we don't have to write. The second best is code that anyone can understand and maintain.
- Adhere to SOLID principles, but do not over-engineer. Balance it against YAGNI and KISS principles.
- Add an abstraction only when it removes reader load, repeated domain logic, or invalid states. One-caller wrappers, speculative extension points, and indirection without a second consumer do not earn their place.
- Write code that follows the principle of least surprise. Avoid cleverness, magic, and hidden behavior. Code should be obvious to a reader who is familiar with the language and framework.
- Build small, complete vertical slices.
- Prefer the simplest sufficient solution; do not build for hypothetical needs.
- Tolerate duplication until a clear abstraction improves readability, usually around the third occurrence.
- Prefer explicit transformations and immutable data over hidden state and unnecessary indirection.
- For stateful or branch-heavy logic, name the domain shape before writing code. Prefer a state machine, table, registry, reducer, or typed model over scattered conditionals.
- Parse and validate untrusted values at system boundaries. Keep internal logic typed and direct. Do not use casts or ignored errors to silence the compiler.
- When an instruction recurs, encode it as a test, lint rule, script, type, or runtime check instead of adding more prose.
- Discuss framework changes, major refactors, and system design with James before implementation.

## Verification

- After completing a change, verify the real artifact before declaring it done. Building, type checking, and unit tests are necessary where relevant, but they do not replace exercising the changed path.
- For bugs, reproduce the failure first on the matching surface. Trace it to its root cause, then verify the original reproduction passes after the fix. Do not ship speculative guards that only hide the symptom.
- Prefer deterministic, rerunnable checks over one-time inspection. For non-trivial work, build the smallest script, harness, codemod, or comparison tool that performs or proves the change.
- Break multi-step work into small verifiable units. Check each unit before starting the next. Order commits so the sequence shows the proof, such as failing test then fix, baseline then treatment, or subtraction then reshape.
- Verify delegated work from its artifacts. Inspect the diff, files, and runtime behavior yourself instead of trusting the delegate's summary.
- If verification cannot run, say that the result is inconclusive and name the blocker.

## Delegation

- Route large searches and raw output through subagents. Keep the main thread focused on decisions, evidence, and concise summaries.

## Naming

- Name things for the domain decision or human action they represent, not their data shape, implementation detail, or provider API.
- Names should explain the job at the call site without requiring the reader to open the implementation.
- Avoid vague buckets such as `data`, `input`, `payload`, `source`, and `files` when a domain-specific name exists.
- If a name could fit ten unrelated contexts, it is too generic.

## Skill Routing

Always invoke the matching skill for these workflows; never perform them manually.

| Intent | Skill |
| --- | --- |
| Review an MR, branch, or code change | `code-review` |
| Run a harsh maintainability review | `thermo-nuclear-code-quality-review` |
| Address or triage MR feedback | `mr-comment-triage` |
| Produce the morning MR status report | `morning-report` |
| Create a standalone Jira ticket | `create-ticket` |
| Review, create, update, or work on GitHub issues | `github-issue-workflow` |
| Write in James's tone or writing style | `writing-style` |
| Explain, teach, or break down a technical topic | `explain` |
| Simplify or reduce code complexity | `simplify` |
| Synthesize useful knowledge from past sessions | `synthesize-brain` |
| Commit changes | `commit` |
| Create an MR or stacked MRs | `merge-request` |
| Monitor an MR, CI, or Greptile | `babysit` |
| Create or remove a workspace | `workspace` |
| Manage files in James's bare dotfiles repository | `dotfiles` |

## Non-Negotiables

- Use Jujutsu, not Git, for version control. Keep distinct and follow-up changes in separate commits. Never use `jj squash` unless James explicitly asks to squash two specific commits.
- Never deploy code, alias or roll back a production deployment, or change production deployment environment variables without James's explicit approval in the current conversation.
- Never publish anything to Slack or communicate as James unless James explicitly asks; even then, obtain confirmation immediately before posting. Drafting messages for James to send is allowed.
