---
name: quick-fix
description: Formalize a fix already in the working copy — create a Jira ticket for it, then jj bookmark, describe, and push to GitLab. Triggered by "quick fix", "quick bug", "log a bug", "create bug ticket", or when James has already made a change and needs to wrap it in a ticket and bookmark. For standalone tickets unrelated to a working-copy change, use the create-ticket skill instead.
---

# Quick Fix

Take a change **already in the working copy** and formalize it: create a Jira
ticket for it, then bookmark, describe, and push the commit to GitLab.

This skill does NOT write code — it assumes the fix already exists. The Jira
ticket creation is **delegated to the `create-ticket` skill**, which owns all Jira
mechanics. quick-fix adds the diff analysis up front and the jj/git steps at the
end.

## Workflow

### 1. Analyze the Fix

```bash
jj diff
jj st
```

From the diff and conversation, derive:

- **Summary**: Concise description (50–80 chars)
- **Description**: What was broken, root cause, what changed, file:line references

quick-fix always uses fixed defaults — the work is already done, so don't ask:

- **Issue Type**: always **Bug** (`10004`)
- **Work Type**: always **Sustaining** (`10586`)
- **Assignee**: always **James** (do not ask)

### 2. Create the Ticket (delegate to create-ticket)

Run the `create-ticket` skill's flow with the details from step 1, but with
quick-fix's fixed defaults — **skip the issue-type and assignment prompts** (Bug +
assign James are always correct here). That skill handles, in order:

1. Creating the ticket as a **Bug** (`10004`), **Sustaining** (`10586`), with the
   correct numeric IDs (see its `jira-reference.md`)
2. **Epic selection** — still recommend the best-fit epic + alternatives + "no
   epic" and elicit James's choice (this is the one prompt quick-fix keeps)
3. Applying epic + **assigning James** (and re-sending Work Type so it doesn't
   reset)

Do not duplicate Jira IDs or field details here — they live in
`../create-ticket/jira-reference.md`. If the returned key isn't `AGP-…`, STOP per
that skill's validation rule.

### 3. Bookmark, Describe, Push

**Bookmark:** `agp-NNNN-short-description` — all lowercase, kebab-case, ≤50 chars,
prefixed with the ticket ID.

**Commit message:** all lowercase, no ticket ID, ≤50 chars.

```bash
jj bookmark create agp-NNNN-short-description
jj describe -m 'lowercase short description, no ticket id'
jj git push --bookmark agp-NNNN-short-description
```

### 4. Report

```
Created AGP-XXXX: [summary]
  Jira:     https://zapierorg.atlassian.net/browse/AGP-XXXX
  Type:     Bug
  Epic:     AGP-NNN [epic summary] (or none)
  Assignee: James Baldwin
  Bookmark: [bookmark-name]
  Pushed:   yes

  ⚠ Set manually: sprint

Ready for MR — say "create MR" when you want to open it.
```
