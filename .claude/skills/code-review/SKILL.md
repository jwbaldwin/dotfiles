---
name: code-review
description: Review a GitLab merge request, GitHub pull request, jj branch, or working-copy change. Use when the user asks for a code review or wants changes checked before merging
license: MIT
metadata:
  version: "1.0"
---
Review the requested change using the available repository and provider tools. Keep the review read-only unless James asks for fixes.

## When to Use This Skill
Activate this skill when:
- The user types "review" or "code review" (with or without slash command)
- The user types "review BRANCH-NAME" to review a specific branch
- The user types "review TICKET-ID" (e.g., "review AGP-123" or "review AICC-456") to review the branch associated with a Jira ticket
- The user types "review LINK_TO_GITLAB_MR", in this case use an available GitLab integration to fetch the MR details; discover its actions rather than guessing tool names
- The user asks to review a branch, pull request, merge request, or uncommitted changes

## Establish the review scope

- Read the repository instructions and the issue or agreed goal behind the change
- Use jj for local state. Identify the base and reviewed revisions, and include working-copy changes when requested. Compare the full requested change, not just the latest commit; inspect nearby code and callers where behavior depends on them
- Use the available GitLab or GitHub integration for remote metadata and diffs. Consult installed command help when needed
- Read existing approved facts, plans, or Jira acceptance criteria as evidence of intent. Reviewing code does not require launching a Plannotator session; use its review UI only when James requests it

## Check requirements as well as defects

Compare the implementation with each agreed behavior: what is satisfied, missing, incorrect, or outside the requested scope? Follow the actual code path and relevant tests rather than treating a checked box or passing test as proof. If a requirement is unclear or unavailable, state the uncertainty instead of inventing one.

Keep this requirements check distinct from the code-quality review below. Correctness, security, concurrency, and integration defects still matter even if the spec never mentions them. For a substantial change, independent reviewers can inspect requirements and code quality; a small diff does not need forced parallel review.

Keep in mind I suspect this code is 100-90% AI generated (with _some_ light human in the loop) and as such look out for halmarks of AI generated code. They mostly boil down to LLM's optimizing for token generation (it's cheap) whereas humas optimize for readability and maintainability (less tokens often leads to this as reading andwriting tokens is far more expensive for a human than an LLM).

### 1. Review for LLM optimizing for tokens rather than humans
Example: MR contains changes to a `types.ts` file, the LLM re-used a list of strings 4 times instead of creating an enum type. That's because the repetition was cheap for the LLM, but a human would never do that because we'd realize that if we ever needed to add something to this list we'd need to add it in 4+ places and for a human that takes time.

Token-inefficient patterns:
- Repeated domain logic where a shared function or type would reduce reader load, usually around the third occurrence
- Verbose names and excessive comments restating obvious code
- Try-catch blocks everywhere, redundant null checks, defensive code that adds no value
- Over-explicit types that could be inferred

Missing abstraction:
- Duplicated domain decisions that can drift apart
- Repeated solutions where a shared implementation would be clearer, without demanding utilities for one-off work
- Ignoring existing patterns/helpers in the codebase
- Breaking simple logic into unnecessary pieces (wrong kind of abstraction)

Context blindness:
- Not following codebase conventions or framework idioms
- Database N+1 queries instead of joins/batching
- React: wrong hook dependencies or avoidable rendering work with a concrete performance consequence; do not require memoization by default
- Generic naming (handler, manager, service) without specificity

Over-engineering vs under-abstracting:
- Adding unused interfaces, config options, extensibility
- But also repeating the same literal code because tokens are free
- Humans find the right level: abstract what repeats, keep simple things simple


### 2. Can we achieve the same result but simpler?

This is the most important question in a review. For every MR, ask: is there a way to get the same behavior with less machinery?

If the answer is yes, propose the simpler alternative concretely — explain what the MR does today, what changes, and what goes away.

### 3. Code quality
- Logic correctness and edge cases
- Error handling and validation, logging
- SOLID principles adherence, DRY but only after the rule of three
- Performance implications (database queries are efficient, indexes, etc.)
- Resource management (memory leaks, connection handling)
- Concurrency issues if applicable

### 4. Test quality
- Tests actually test the intended behavior
- Setup is clear and concise (refactored if repeated)
- Tests are small and focused and provide confidence that the change works
- Tests are clear and maintainable by humans
- Tests serve as good documentation for the code behavior

### 5. Dependencies and Integration
- New dependencies added
- Database migration requirements

### 6. Human review guidance
- Provide a clear breakdown of the changes (simple, concise, no jargon)
- The key files to review
- Propose an order for reviewing the changes
