---
name: code-review # Must match directory name
description: Review a Gitlab Merge Request. Use when the user says "review" or "code review" or asks to review pull requests, merge requests, or analyze branch changes before merging
license: MIT
allowed-tools: 
  - read
  - write
metadata:
  version: "1.0"
---
Review the given Gitlab MR (provided after this, use Zapier MCP to review the changes).

## When to Use This Skill
Activate this skill when:
- The user types "review" or "code review" (with or without slash command)
- The user types "review BRANCH-NAME" to review a specific branch
- The user types "review TICKET-ID" (e.g., "review AGP-123" or "review AICC-456") to review the branch associated with a Jira ticket
- The user types "review LINK_TO_GITLAB_MR", in this case use Zaper MCP to fetch the MR details
- The user asks to review a branch, pull request, or merge request

Keep in mind I suspect this code is 100-90% AI generated (with _some_ light human in the loop) and as such look out for halmarks of AI generated code. They mostly boil down to LLM's optimizing for token generation (it's cheap) whereas humas optimize for readability and maintainability (less tokens often leads to this as reading andwriting tokens is far more expensive for a human than an LLM).

### 1. Review for LLM optimizing for tokens rather than humans
Example: MR contains changes to a `types.ts` file, the LLM re-used a list of strings 4 times instead of creating an enum type. That's because the repetition was cheap for the LLM, but a human would never do that because we'd realize that if we ever needed to add something to this list we'd need to add it in 4+ places and for a human that takes time.

Token-inefficient patterns:
- Repeating code blocks instead of extracting functions/types after 2+ uses
- Verbose names and excessive comments restating obvious code
- Try-catch blocks everywhere, redundant null checks, defensive code that adds no value
- Over-explicit types that could be inferred

Missing abstraction:
- Not DRYing up repetition
- Creating one-off solutions instead of reusable utilities
- Ignoring existing patterns/helpers in the codebase
- Breaking simple logic into unnecessary pieces (wrong kind of abstraction)

Context blindness:
- Not following codebase conventions or framework idioms
- Database N+1 queries instead of joins/batching
- React: wrong hook deps, missing memoization, unnecessary re-renders
- Generic naming (handler, manager, service) without specificity

Over-engineering vs under-abstracting:
- Adding unused interfaces, config options, extensibility
- But also repeating the same literal code because tokens are free
- Humans find the right level: abstract what repeats, keep simple things simple


### 2. Code quality
- Logic correctness and edge cases
- Error handling and validation, logging
- SOLID principles adherence, DRY but only after the rule of three
- Performance implications (database queries are efficient, indexes, etc.)
- Resource management (memory leaks, connection handling)
- Concurrency issues if applicable

### 3. Test quality
- Tests actually test the intended behavior
- Setup is clear and concise (refactored if repeated)
- Tests are small and focused and provide confidence that the change works
- Tests are clear and maintainable by humans
- Tests serve as good documentation for the code behavior

### 4. Dependencies and Integration
- New dependencies added
- Database migration requirements

### 5. Human review guidance
- Provide a clear breakdown of the changes (simple, concise, no jargon)
- The key files to review
- Propose an order for reviewing the changes

