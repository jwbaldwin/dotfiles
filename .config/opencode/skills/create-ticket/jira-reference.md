# Jira Reference (MCP)

Source of truth for all Jira mechanics in the MCP project. Both `create-ticket`
and `quick-fix` rely on this. Prefer the stable numeric IDs below. The direct Jira
tool surface currently resolves `MCP` correctly, but numeric IDs avoid ambiguity
across connector surfaces.

## Identifiers

| Thing                     | Value to pass                                  |
| ------------------------- | ---------------------------------------------- |
| `selected_api`            | `JiraSoftwareCloudCLIAPI`                       |
| Project (key `MCP`)       | `11589`                                       |
| James's account ID        | `712020:b89b36ad-2ce4-4fca-ab2b-4dc06a0b510c`  |

## Issue Type IDs

Pass the numeric ID as `issuetype`, never the label (e.g. `"Bug"` fails with
"'Bug' is not a valid id").

| Issue Type   | ID      |
| ------------ | ------- |
| Epic         | `10000` |
| Story        | `10001` |
| Sub-task     | `10003` |
| Bug          | `10004` |
| Initiative   | `10005` |
| Design Task  | `10021` |
| Security Bug | `10239` |
| Spike        | `10607` |

## Work Type (customfield_10346)

Use the field key `option::customfield_10346` (NOT `string::`). Pass the numeric
option ID:

| Work Type  | ID      | When                          |
| ---------- | ------- | ----------------------------- |
| New        | `10585` | New features / new work       |
| Sustaining | `10586` | Bug fixes / maintenance       |

### ⚠ update_issue resets Work Type

`update_issue` silently resets Work Type to `New` (`10585`) whenever you call it
without re-sending the field. ALWAYS include `"option::customfield_10346"` in any
`update_issue` call, then verify `fields.customfield_10346.value` in the response.
If it flipped, re-send the update with just the Work Type to fix it.

## Jira tool surfaces

The integration can appear in either form:

- Generic Zapier tools: inspect the action, then call the corresponding
  `execute_zapier_*_action` tool with action keys such as `create_issue`,
  `issue_jql`, and `update_issue`.
- Direct Jira tools on `$ZAPIER_MCP_URL`:
  `jira_software_cloud_find_issues_via_jql`,
  `jira_software_cloud_create_issue`, and
  `jira_software_cloud_update_issue`. Before a direct create or update, call
  `get_dynamic_properties_schema`; call `list_dynamic_enum_values` for fields
  marked as dynamic enums.

The direct create schema for project `11589` accepts summary, description, Work
Type, parent, and assignee in `dynamic_properties`. Prefer setting all known
fields during creation so a later update is unnecessary.

## Generic create_issue — field support

| Field       | create_issue | How                                          |
| ----------- | ------------ | -------------------------------------------- |
| Project     | ✅           | `project: "11589"`                           |
| Issue Type  | ✅           | `issuetype: "<id>"` (e.g. `10004` Bug)       |
| Assignee    | ⚠ unreliable | Prefer setting via `update_issue` (below)    |
| Summary     | ✅           | `string::summary`                            |
| Description | ✅           | `string::description`                        |
| Work Type   | ✅           | `option::customfield_10346`                  |
| Epic/Parent | ❌           | Set via `update_issue` `issuelink::parent`   |
| Sprint      | ❌           | Resolver ignores; set manually in Jira       |

Assignee via the `instructions` text on `create_issue` is unreliable. The reliable
path is `update_issue` with `user::assignee` set to the account ID.

## update_issue — epic + assignee

```
zapier-mcp_execute_zapier_write_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "update_issue",
  params: {
    issueKey: "MCP-NNNN",
    "issuelink::parent": "MCP-690",        // epic KEY, not ID
    "user::assignee": "712020:b89b36ad-2ce4-4fca-ab2b-4dc06a0b510c",
    "option::customfield_10346": "10586"   // re-send Work Type or it resets to New
  }
})
```

- `issuelink::parent` takes the epic **key** (e.g. `MCP-690`), not the numeric ID.
- `user::assignee` takes the **account ID**.

## Fetch open epics (for epic selection)

```
zapier-mcp_execute_zapier_read_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "issue_jql",
  params: {
    jql: "project = MCP AND issuetype = Epic AND statusCategory != Done ORDER BY updated DESC",
    fields: "summary,status,updated"
  }
})
```

Frequently used open epics as of 2026-08-17 (always verify live):

- `MCP-2289` Tech Debt — cleanup, testing infrastructure, observability hygiene
- `MCP-2288` Bugs — broken behavior and defect fixes
- `MCP-2351` Workflows Agentic UX — workflows agent experience

Do not use completed epics `MCP-1684` (Test Infrastructure) or `MCP-1634`
(Production Stability & Scalability) for new tickets. `MCP-690` is now the open
epic named Backlog, not Code & Flag Cleanup.

## Fetch a ticket by key

```
zapier-mcp_execute_zapier_read_action({
  selected_api: "JiraSoftwareCloudCLIAPI",
  action: "issue_jql",
  params: {
    jql: "key = MCP-NNNN",
    fields: "summary,description,issuetype,priority,status"
  }
})
```

## Validation rule

After `create_issue`, if the returned key does NOT start with `MCP-`, STOP — the
integration filed it in the wrong project. Hand James the summary/description for
manual creation rather than continuing.
