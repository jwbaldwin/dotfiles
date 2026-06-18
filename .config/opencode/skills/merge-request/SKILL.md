---
name: merge-request
description: Create one or more small stacked GitLab merge requests from jj bookmarks. Triggered by "create MR", "create merge request", "open MR", "submit for review", "put up the MR", "create stacked MRs", or "open the stack".
---

# Create Merge Request

Create GitLab MRs from jj bookmarks. Prefer small, independently reviewable MRs over one large MR when the local jj stack can be split cleanly.

## Repository Config

| Repository | Path | Project ID | Default Target | GitLab Path |
|------------|------|------------|----------------|-------------|
| MCP | `/Users/jbaldwin/repos/mcp` | 71810865 | `main` | `zapier/team-agents-platform/mcp` |
| AI Command Center | `/Users/jbaldwin/repos/ai-command-center` | 48901663 | `staging` | `zapier/zapai/ai-command-center` |

### Default Reviewers

Pick **two** of these at random for each MR unless James specifies reviewers. Never add more than two.

| Name | GitLab Username |
|------|----------------|
| Nate Moore | `neat.moore` (ID: 16898407) |
| Dylan Laible | `dylan.laible` (ID: 31252789) |
| Marco Costa | `marco.costa6` (ID: 35597336) |
| Daniel Vagg | `daniel.vagg` (ID: 23002286) |

## Default Policy: Small MRs

- Creating more MRs is good when it lowers reviewer cognitive load and each MR is independently understandable.
- Use jj as the local stack manager. GitLab should receive one source bookmark per reviewable change.
- For stacked work, create GitLab MRs where each child MR targets its parent bookmark. This gives GitLab a stacked-diff view instead of one giant diff against trunk.
- Do not split a change just to inflate count. Each MR needs a coherent purpose, tests/checks that make sense for that slice, and a clear review order.
- If the right split requires significant history surgery, pause and ask James before rearranging commits/bookmarks.

## Workflow

### 1. Detect Repository

Check the current working directory to determine the repo. If unclear, ask James.

### 2. Gather Stack Context

```bash
jj st
jj log -r 'mine()' --no-pager
jj bookmark list
jj diff
```

Extract:

- **Current bookmark**: the source branch for a single MR, or the tip of a stack.
- **Ticket ID**: extract from bookmark names when possible, then uppercase it, e.g. `agp-782` -> `AGP-782`.
- **Reviewable slices**: look for bookmarks/commits that are coherent, small, and can be reviewed independently.
- **Existing remote tracking**: determine which bookmarks already exist on GitLab.

If uncommitted work exists, do not open an MR for it. Ask James whether to commit it first, or use the `commit` skill if he says to commit.

### 3. Decide Single MR vs Stack

Use a single MR when:

- There is only one coherent change.
- Splitting would make reviewers jump between tightly coupled incomplete pieces.
- The change is already small enough for a quick review.

Use stacked MRs when:

- The work naturally separates into setup, behavior, tests, cleanup, or follow-up slices.
- Multiple bookmarks already represent those slices.
- Reviewers would benefit from seeing each slice as its own MR.

For a stack, identify ordered pairs:

```text
source bookmark -> target branch/bookmark
```

The bottom MR targets the repo default target (`main` or `staging`). Each next MR targets the bookmark immediately below it.

Example:

```text
agp-100-add-schema       -> main
agp-100-wire-handler     -> agp-100-add-schema
agp-100-add-followups    -> agp-100-wire-handler
```

If the stack shape is ambiguous, show James the proposed MR list and ask before creating anything.

### 4. Push Bookmarks To GitLab

The branch must end up on GitLab, not just in a local clone.

First check where `origin` points:

```bash
jj git remote list
```

If `origin` is GitLab, push each source bookmark and each bookmark used as a target branch:

```bash
jj git push --bookmark <bookmark-name> --allow-new
```

If there are tracking errors, fix them:

```bash
jj bookmark track <bookmark-name>@origin
jj git push --bookmark <bookmark-name>
```

If this is a workspace and `origin` is a local clone path, `jj git push` only updates that local clone. Push to the clone first, then push from the clone to GitLab:

```bash
jj git push --bookmark <bookmark-name> --allow-new
git -C <clone-path> push -u origin <bookmark-name>
```

Confirm GitLab has every source and stacked target branch before creating MRs. If MR creation fails with `source_branch: does not exist` or `target_branch: does not exist`, the branch did not reach GitLab.

### 5. Build MR Titles

Format: `[TICKET-ID] Short description`

- Prefer each bookmark or commit message's actual purpose, not a vague umbrella title.
- Keep titles concise, ideally under 72 chars.
- If James says `draft MR` or `WIP`, prefix the title with `Draft: `.

Example stack titles:

```text
[AGP-100] Add action schema
[AGP-100] Wire action execution handler
[AGP-100] Add execution follow-up tests
```

### 6. Get Description From James

**STOP. Do NOT write descriptions yourself. Do NOT proceed to MR creation until James has responded.**

Ask James: `What should the MR description be? Or should I leave it blank for you to fill in?`

- If creating multiple MRs, ask whether James wants one shared description, per-MR descriptions, or blanks.
- If James provides text, use it verbatim.
- If James says to leave it blank, use an empty description.
- If James does not respond or says anything ambiguous, use an empty description.

Never draft, summarize, or generate descriptions on your own. James writes his own MR descriptions.

### 7. Create The MR Or Stack

Use Zapier MCP GitLab actions. Always inspect enabled Zapier actions before executing them in the active session; do not guess action names.

For each MR:

```text
create merge request with:
  title: "[TICKET-ID] Description"
  project_id: "<project_id>"
  source_branch: "<source-bookmark>"
  target_branch: "<target-branch-or-parent-bookmark>"
  description: "<description or empty>"
```

Create bottom-to-top so target bookmark MRs exist before dependent MRs.

### 8. Assign Reviewers And James

After each MR is created, pick two reviewers from the default list and assign them with the GitLab API. Assign James as assignee (`assignee_id=29954463`).

Use the comma-separated `reviewer_ids` form: `reviewer_ids=ID1,ID2`. Do not use `reviewer_ids[]=a&reviewer_ids[]=b`; through Zapier raw request the repeated brackets collapse to one value.

```text
PUT https://gitlab.com/api/v4/projects/<project_id>/merge_requests/<iid>?reviewer_ids=<id1>,<id2>&assignee_id=29954463
```

Confirm the response `reviewers` array contains both names. If either is missing, look up the correct member and retry.

### 9. Report

For a single MR:

```text
MR created: [TICKET-ID] Description (!<iid>)
  URL: https://gitlab.com/.../-/merge_requests/<iid>
  Reviewers: <two reviewers>
  Target: <target_branch>
```

For a stack:

```text
Stacked MRs created:
1. [TICKET-ID] First slice (!<iid>)
   URL: <url>
   Source -> target: <bookmark> -> <default-target>
2. [TICKET-ID] Next slice (!<iid>)
   URL: <url>
   Source -> target: <bookmark> -> <parent-bookmark>

Review order: bottom to top.
```

If James asks you to babysit the MR after creation, use the `babysit` skill.

## Important Notes

- Always push bookmarks before creating MRs, and make sure they land on GitLab.
- If no bookmark exists yet, prompt James to create one with `jj bookmark create`.
- Prefer small stacked MRs, but do not restructure history without James's explicit approval.
- If James specifies reviewers or a target branch, use those instead of the defaults.
- Use `jj`, not `git`, for local version-control state. Use `git -C <clone-path> push` only for the workspace-to-GitLab bridge described above.
