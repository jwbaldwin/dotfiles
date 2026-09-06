---
name: mr-comment-triage
description: Assess GitLab merge request feedback and draft replies in James's writing style. Use when James asks to triage comments, review MR feedback, investigate reviewer questions, estimate changes, draft replies, or address feedback. Triage is read-only; edit code only when James asks to address or fix the feedback.
---

# MR Comment Triage

Triage review feedback on a GitLab merge request and turn each comment into an assessment and a draft reply: what the code does, what should change (if anything), and why.

Read and apply `../writing-style/SKILL.md` before writing the assessment and draft replies. Keep them concrete, concise, and in James's voice.

“Triage these” means investigate, assess, and draft. Do not edit code, post replies, or resolve threads. “Address/fix these comments” authorizes code edits within the requested scope; posting still requires the global communication approval.

## Repository Mapping

| Repository        | Path                                      | Project ID | GitLab Path                       |
| ----------------- | ----------------------------------------- | ---------- | --------------------------------- |
| MCP               | `/Users/jbaldwin/repos/mcp`               | `71810865` | `zapier/team-agents-platform/mcp` |
| AI Command Center | `/Users/jbaldwin/repos/ai-command-center` | `48901663` | `zapier/zapai/ai-command-center`  |

If the repository is unclear, ask James for the project.

## Workflow

### 1) Gather MR and Comment Context

1. Identify the MR via URL or IID. If missing, ask James.
2. Fetch discussions and focus on unresolved threads first.
3. Normalize each thread into:
   - comment text
   - author
   - file + line (for diff notes)
   - discussion id
   - resolved/unresolved

Preferred API flow (Zapier MCP):

```text
zapier-mcp_list_enabled_actions({ app: "gitlab" })
zapier-mcp_execute_write_action({
  app: "gitlab",
  action: "_zap_raw_request",
  instructions: "Fetch MR discussions",
  output: "Return unresolved discussions with ids, note bodies, authors, file/line, and resolved flag",
  params: {
    method: "GET",
    url: "https://gitlab.com/api/v4/projects/<project_id>/merge_requests/<iid>/discussions?per_page=100"
  }
})
```

### 2) Classify Each Comment

| Type             | Typical signal                         | Default action                                              |
| ---------------- | -------------------------------------- | ----------------------------------------------------------- |
| `nit`            | wording/style/minor cleanup            | assess whether a small change is worthwhile and draft a reply |
| `question`       | asks why/how, no direct change request | investigate and answer with evidence                        |
| `change-request` | asks for behavior/logic update         | scope the change and impacts before coding                  |
| `concern`        | challenges approach or tradeoff        | explain reasoning, propose alternatives, escalate if needed |

If uncertain between `question` and `change-request`, treat it as `change-request` and do impact analysis.

### 3) Investigate Before Replying

For every comment, including nits, inspect enough current code to establish whether the feedback still applies:

- Read relevant code, tests, and call sites.
- Confirm current behavior from code, not assumptions.
- Identify implications: correctness, API behavior, performance, security, migration risk.
- Note what needs updating (code, tests, docs, OpenAPI, handlers).

Always cite concrete file references in the final response.

### 4) Take the Correct Path

#### A) `nit`

- Assess whether the edit improves the code or wording.
- State the proposed edit and why it is worth making, or explain why no change is needed.
- Draft a reply without claiming the change is already fixed.

#### B) `question` (no code change)

- Answer directly with evidence and short rationale.
- Include file references.
- State explicitly that no code change is needed.

#### C) `change-request`

- Propose the minimal safe change.
- List implications before coding:
  - behavior changes
  - touched modules/contracts
  - tests to add/update
  - risk/regression areas
- Keep the change as a proposal unless James has asked to address or fix the feedback.

#### D) `concern`

- Explain tradeoffs crisply.
- Offer options when there is no single obvious answer.
- Escalate to James when the decision is architectural or product-facing.

### 5) Assessment And Draft Replies To James

For each comment, identify the thread or file/line and provide:

- **Assessment:** whether the feedback applies to the current code, what should change or what answers the question, and why. Cite the relevant code. Include impact or a decision needed from James only when it matters.
- **Draft reply:** text James can send, following `../writing-style/SKILL.md`. Explain the concrete what and why without repeating the full investigation.

Distinguish proposed changes from completed ones. Do not write “fixed” or “updated” until the edit has actually been made. For an unapproved proposal, use wording such as “I’d change X because Y.” Keep small nits short rather than filling a fixed set of headings.

### 6) Batch Handling Multiple Comments

When many comments exist, produce a triage list first:

- `comment-id`: type, recommendation, complexity (`S`, `M`, `L`)
- suggested order if James chooses to make changes
- blockers requiring a James decision

### 7) When James Requests Fixes

- Apply the requested fixes that the investigation supports; do not implement stale or incorrect feedback just because a reviewer asked.
- Discuss material product or architecture choices before editing.
- Run the repository's checks appropriate to the changed behavior. Do not assume `pnpm` scripts exist, or broaden/repeat checks without a change, failure, or unresolved concern to justify it.
- Update the assessment and draft replies to reflect what actually changed and why. Leave posting and thread resolution to a separately authorized action.

## Guardrails

- Do not assume reviewer intent; restate it before acting.
- Prefer minimal changes (YAGNI) unless broader refactor is clearly required.
- Use `jj`, not `git`, for version-control commands.
- If uncertainty affects implementation, ask one targeted question.
