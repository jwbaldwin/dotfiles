---
name: mr-comment-triage
description: Triage and respond to GitLab merge request comments. Use when James asks to review MR feedback, decide whether a comment is a quick nit or deeper concern, investigate code to answer reviewer questions, estimate code-change implications, or draft concise replies.
---

# MR Comment Triage

Triage review feedback on a GitLab merge request and turn each comment into a clear next action: quick fix, technical answer, scoped change plan, or discussion escalation.

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
| `nit`            | wording/style/minor cleanup            | make a small change quickly                                 |
| `question`       | asks why/how, no direct change request | investigate and answer with evidence                        |
| `change-request` | asks for behavior/logic update         | scope the change and impacts before coding                  |
| `concern`        | challenges approach or tradeoff        | explain reasoning, propose alternatives, escalate if needed |

If uncertain between `question` and `change-request`, treat it as `change-request` and do impact analysis.

### 3) Investigate Before Replying

For `question`, `change-request`, or `concern`:

- Read relevant code, tests, and call sites.
- Confirm current behavior from code, not assumptions.
- Identify implications: correctness, API behavior, performance, security, migration risk.
- Note what needs updating (code, tests, docs, OpenAPI, handlers).

Always cite concrete file references in the final response.

### 4) Take the Correct Path

#### A) `nit`

- Implement the small edit.
- Run checks: `pnpm types`, `pnpm lint`, `pnpm fmt`.
- Draft a short reply that it is fixed.

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
- If requested, implement and validate.

#### D) `concern`

- Explain tradeoffs crisply.
- Offer options when there is no single obvious answer.
- Escalate to James when the decision is architectural or product-facing.

### 5) Response Format (Per Comment) To James

Use this structure:

1. `Classification`
2. `Understanding` (one sentence restatement)
3. `Findings` (with file references)
4. `Plan` or `Answer`
5. `Impact`
6. `Reply draft` (text ready to post in MR)

### 6) Batch Handling Multiple Comments

When many comments exist, produce a triage list first:

- `comment-id`: type, recommendation, complexity (`S`, `M`, `L`)
- execution order: quick nits first, then deeper items
- blockers requiring a James decision

## Guardrails

- Do not assume reviewer intent; restate it before acting.
- Prefer minimal changes (YAGNI) unless broader refactor is clearly required.
- Use `jj`, not `git`, for version-control commands.
- If uncertainty affects implementation, ask one targeted question.
