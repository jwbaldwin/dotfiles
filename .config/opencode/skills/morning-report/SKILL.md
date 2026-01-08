---
name: morning-report
description: Generate a morning MR status report. Use when the user says "morning report", "mr status", "what needs my attention", or similar morning standup queries.
license: MIT
allowed-tools:
  - read
  - write
metadata:
  version: "1.3"
---

# Morning Report

Generate a GitLab MR status report for James. This is an AI assistant giving a morning briefing - use natural language, not terse shorthand.

## When to Use This Skill

Activate this skill when:

- The user says "morning report" or "morning"
- The user asks "what MRs need my attention?"
- The user asks about their MR status
- The user wants to know what to review

## Workflow

### 1. Fetch My Open MRs

Use Zapier MCP to get all open MRs created by James:

```
zapier-mcp_gitlab_find_all_merge_requests({
  instructions: "Find all open merge requests that I created",
  scope: "created_by_me",
  state: "opened"
})
```

### 2. Fetch MRs Needing My Review

Use Zapier MCP raw API to get MRs where James is a reviewer:

```
zapier-mcp_gitlab_api_request_beta({
  instructions: "Get all open merge requests where I am a reviewer",
  method: "GET",
  url: "https://gitlab.com/api/v4/merge_requests?state=opened&reviewer_username=james.baldwin.z&scope=all"
})
```

### 3. For Each of My MRs, Gather Approval Status and Discussions

Fetch approval status and discussions in parallel for all of James's MRs:

```
zapier-mcp_gitlab_api_request_beta({
  instructions: "Get approval status for MR [iid] in project [project_id]",
  method: "GET",
  url: "https://gitlab.com/api/v4/projects/[project_id]/merge_requests/[iid]/approvals"
})

zapier-mcp_gitlab_api_request_beta({
  instructions: "Get discussions for MR [iid] in project [project_id]",
  method: "GET",
  url: "https://gitlab.com/api/v4/projects/[project_id]/merge_requests/[iid]/discussions"
})
```

### 4. Analyze Discussions for Feedback

For each of James's MRs, analyze the discussions to determine:

1. **Unresolved threads count** - threads where `resolvable === true && resolved === false`
2. **Recent feedback** - look for notes from other users (not James) in the last 24-48 hours
3. **Feedback summary** - extract key points from recent comments

When summarizing feedback:

- If there are 1-2 short comments, include the actual feedback text
- If there are many comments or long discussions, summarize as "X unresolved threads to address"
- Always attribute feedback to the reviewer (e.g., "Lucas asked about...")
- Focus on actionable items and questions

### 5. Generate Report

Use the indented hierarchy format below. Write like an AI assistant giving a morning briefing - natural language, not terse keywords.

## Output Rules

1. **Indented hierarchy, not tables** - Tables don't render well in the terminal
2. **Natural language** - Write "rebase with main" not "rebase". Write "From Lucas, opened 9 days ago" not "Lucas, 9d"
3. **Include the repo** - Show which repo each MR is in (e.g., `mcp` or `ai-command-center`)
4. **Bold the MR titles** - Use `**[TICKET] title (!XXX)**` format
5. **Truncate titles** - If MR title is long, shorten it but keep the ticket ID
6. **Skip most labels** - Only include labels that convey review urgency (like "review-in-depth")
7. **No branches** - James knows his branches
8. **Relative time** - "opened 9 days ago" not "2025-12-22"
9. **Stacked MRs** - Note when MRs are stacked/dependent so James knows review order
10. **Links at the bottom** - Keep the main report clean, put all URLs in a Links section at the end
11. **Summary line** - End with a count of MRs waiting on action and MRs in review queue
12. **Greeting** - Start with "Good morning, James" and the date
13. **Show reviewer feedback** - For James's MRs with new comments or unresolved threads:
    - Show unresolved thread count in Status line
    - Add a "Feedback:" line with summary of what reviewers said
    - If feedback is short (1-2 sentences), quote it directly
    - If feedback is long or there are many threads, summarize (e.g., "3 unresolved threads - Lucas asked about error handling, Nate suggested refactoring")
    - Attribute feedback to the reviewer who left it

## Status Determination Logic

For each MR, determine status by checking:

1. **Has Conflicts:** `has_conflicts === true` or `detailed_merge_status === "conflict"` -> "has conflicts"
2. **Draft:** `draft === true` -> "draft"
3. **Unresolved Discussions:** Count threads where `resolvable === true && resolved === false` -> "X unresolved threads"
4. **Not Approved:** Check approvals endpoint -> "X/Y approvals"
5. **Ready to Merge:** `detailed_merge_status === "mergeable"` AND no unresolved threads -> "ready to merge"

**IMPORTANT:** An MR is NOT ready to merge if it has unresolved discussions, even if it has all required approvals.

## Important Notes

- For MRs to review, exclude any authored by James himself
- Group stacked MRs together and note the dependency chain
- If an MR is blocked by another MR, note that in the action
- When an MR is fully approved but has conflicts, the action is "rebase with main, then ready to merge"
- When an MR has unresolved discussions, it is NOT ready to merge even if fully approved
- Only fetch discussions for James's MRs (not the review queue) to minimize API calls
- When summarizing feedback, focus on questions and actionable items, skip "looks good" or approval-only comments
- System notes (like "added X commits") are not feedback - filter these out

## Example Output

```
Good morning, James. Here's your MR status for Monday, January 5th.

## Your MRs

**[AGP-1028] oxfmt (!229)** in `mcp`
  Status: has conflicts, 2/2 approved
  Action: rebase with main, then ready to merge

**[AGP-760] entitlements api (!225)** in `mcp`
  Status: 1/2 approvals, 2 unresolved threads
  Feedback: Lucas asked about the error handling in the feature flag check; Nate suggested adding a test for the edge case
  Action: address feedback, get second approval

**[AGP-1027] oxlint (!223)** in `mcp`
  Status: has conflicts, 0/2 approvals
  Action: rebase with main, request reviews

**[AGP-966] params fix (!4887)** in `ai-command-center`
  Status: 1/1 approved, 1 unresolved thread
  Feedback: Lucas asked "should we also handle the case where resolvedParams is empty?"
  Action: address feedback, then ready to merge

## To Review

**[AGP-973] redirect fix (!4922)** in `ai-command-center`
  From Lucas, opened 9 days ago

**[AGP-1031] MCP self-serve (!4913)** in `ai-command-center`
  From Dylan, opened 17 days ago
  Note: stacked on !4906, review that first

**[AGP-1003] agents self-serve (!4906)** in `ai-command-center`
  From Dylan, opened 17 days ago

**[AGP-953] hashedSecret verify (!224)** in `mcp`
  From Nate, opened 18 days ago
  Note: blocked by !4894, can't merge until that lands

**[AGP-1019] backfill hashed (!4894)** in `ai-command-center`
  From Nate, opened 18 days ago
  Note: stacked on !4890, review that first

**[AGP-952] longer secrets (!4890)** in `ai-command-center`
  From Nate, opened 19 days ago
  Label: review-in-depth

## Priority Actions

1. Rebase your 3 MCP repo MRs - all have conflicts with main
2. Review Nate's secret hashing stack starting at !4890, then !4894, then !224
3. Review Dylan's self-serve stack starting at !4906, then !4913

You have 4 MRs waiting on action and 6 MRs in your review queue.

---

**Links**

Your MRs:
- !229: https://gitlab.com/zapier/team-agents-platform/mcp/-/merge_requests/229
- !225: https://gitlab.com/zapier/team-agents-platform/mcp/-/merge_requests/225
- !223: https://gitlab.com/zapier/team-agents-platform/mcp/-/merge_requests/223
- !4887: https://gitlab.com/zapier/zapai/ai-command-center/-/merge_requests/4887

To Review:
- !4922: https://gitlab.com/zapier/zapai/ai-command-center/-/merge_requests/4922
- !4913: https://gitlab.com/zapier/zapai/ai-command-center/-/merge_requests/4913
- !4906: https://gitlab.com/zapier/zapai/ai-command-center/-/merge_requests/4906
- !224: https://gitlab.com/zapier/team-agents-platform/mcp/-/merge_requests/224
- !4894: https://gitlab.com/zapier/zapai/ai-command-center/-/merge_requests/4894
- !4890: https://gitlab.com/zapier/zapai/ai-command-center/-/merge_requests/4890
```

## Future Consideration

GitLab CLI (`glab`) may be faster than Zapier MCP for fetching data. Worth exploring if report generation feels slow.
