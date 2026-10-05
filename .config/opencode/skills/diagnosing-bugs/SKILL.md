---
name: diagnosing-bugs
description: Diagnose difficult bugs and performance regressions through a symptom-specific reproduction, targeted experiments, and a proven fix. Use when a failure needs investigation rather than an obvious local correction. For deciding whether a production alert needs action, use production-triage first.
---

# Diagnosing Bugs

Build evidence for the cause, then prove the fix against the reported failure. Keep the process proportional to the uncertainty; a clear defect does not need a list of competing theories.

## Establish the failure

- Identify the exact symptom, expected behavior, affected environment, and triggering input or action
- Read relevant code, project instructions, domain documentation such as `CONTEXT.md`, and applicable ADRs while finding the reproduction path
- Build the smallest repeatable check that exercises the actual failing path: a behavioral test, local API request, browser interaction, trace replay, or focused harness
- Run it before changing the implementation and capture the specific failure. A nearby error or a command that merely exits successfully is not evidence about this bug

This step is complete when the check can distinguish the reported failure from the expected behavior and has demonstrated the failure. Prefer a deterministic, fast check; for intermittent bugs, record the conditions, number of attempts, and observed failure rate rather than claiming one passing run proves anything.

If the matching environment or artifact is unavailable, state what prevents reproduction and what evidence is available. Code inspection and provisional hypotheses can continue, but distinguish a suspected cause from a reproduced defect. Ask for the smallest missing artifact or access that would settle the uncertainty. Production instrumentation, deployment, and data changes still require explicit approval.

## Reduce and investigate

1. Remove unnecessary input, setup, or steps one at a time, rerunning the check to preserve the same failure. Keep the original scenario for the final check
2. State the plausible cause and the observation that would confirm or disprove it. Consider competing causes when the evidence does not distinguish them; do not invent hypotheses to meet a quota
3. Choose a probe that separates those explanations: debugger inspection, a targeted log, a query plan, or a controlled change to one variable
4. Run the probe, record the result, and update the explanation before changing more code

For performance regressions, measure a baseline under comparable conditions before optimizing. For history comparisons, use jj and isolated workspaces so experiments do not disturb unrelated changes. Consult the installed command help before using unfamiliar options.

Keep credentials in the environment and redact sensitive values from shared output. Give temporary instrumentation a distinctive marker so it can be found and removed.

## Fix and prove

- Convert the reproduction into a regression test when an existing test boundary can exercise the real failure. Watch it fail before applying the fix
- Fix the cause with the smallest sufficient change, then watch the same check pass
- Rerun the original, unreduced scenario on the matching surface. A unit test does not establish browser behavior, and one successful concurrent run does not establish race freedom
- Run the relevant repository checks and remove temporary probes. If no useful regression test can reach the failure, explain that gap rather than adding a test that gives false confidence

Finish when the original symptom is resolved with evidence, relevant checks pass, and temporary instrumentation is removed. Report the cause and how the change addresses it. If reproduction or final validation remains blocked, name the blocker and keep the conclusion qualified.

Adapted from [Matt Pocock's diagnosing-bugs](https://github.com/mattpocock/skills/tree/24fe0ef7737efae15c87225755e9f6f5965e4888/skills/engineering/diagnosing-bugs), under the [MIT license](LICENSE).
