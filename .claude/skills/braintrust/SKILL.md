---
name: braintrust
description: Query and debug production traces in Braintrust. Triggered by "braintrust", "check traces", "search traces", "debug traces", "braintrust query", or when James asks about production MCP request behavior.
---

# Braintrust

Debug production traces via Braintrust's BTQL (SQL-like) query API. Primarily used for the MCP project.

## Quick Start — btql.sh

Use `scripts/btql.sh` for common queries. It handles the data plane URL, auth, and JSON formatting.

```bash
btql.sh --errors                     # Recent errors (last 24h)
btql.sh --slow 10                    # Traces > 10s (last 24h)
btql.sh --trace <TRACE_ID>           # All spans in a trace
btql.sh --server <SERVER_ID>         # Traces for a server
btql.sh --search "term"              # Full-text search on input
btql.sh --tools                      # Tool execution breakdown (24h)
btql.sh --limit 20 --errors          # More results
btql.sh --project core --errors      # Query ai-command-center instead
btql.sh "SELECT ... FROM ..."        # Raw SQL
```

For complex or custom queries, use `curl` directly (see below).

## Config

| Key | Value |
|-----|-------|
| API key env var | `BRAINTRUST_API_KEY` |
| Data plane (BTQL) | `https://d30590cgs91ici.cloudfront.net` |
| REST API | `https://api.braintrust.dev` |

### Projects

| Project | ID | Repo |
|---------|----|------|
| **MCP** (primary) | `f4078417-106e-4a78-90bf-a97bd9f4d62f` | `/Users/jbaldwin/repos/mcp` |
| Central - Core | `41d8234a-0127-4c9d-a39a-348705066ccf` | `/Users/jbaldwin/repos/ai-command-center` |
| AI Query | `8f99eacc-bdaa-4f39-a4bc-797d114f82fe` | `/Users/jbaldwin/repos/ai-command-center` |

Default to MCP unless James specifies otherwise.

## Querying with BTQL

All queries go through the data plane via `curl`:

```bash
curl -s -X POST "https://d30590cgs91ici.cloudfront.net/btql" \
  -H "Authorization: Bearer $BRAINTRUST_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "<SQL_QUERY>", "fmt": "json"}'
```

**IMPORTANT:** The org uses a custom data plane. BTQL queries MUST go to `https://d30590cgs91ici.cloudfront.net/btql`, NOT `https://api.braintrust.dev/btql`.

REST API calls (list projects, datasets, experiments) still use `https://api.braintrust.dev/v1/`.

### Data Shapes

| Shape | FROM syntax | Returns |
|-------|-------------|---------|
| `spans` (default) | `project_logs('ID', shape => 'spans')` | Individual spans |
| `traces` | `project_logs('ID', shape => 'traces')` | All spans from matching traces |
| `summary` | `project_logs('ID', shape => 'summary')` | One row per trace, aggregated metrics |

### MCP Span Structure

Each MCP request creates spans with these conventions:

| Span Name | Type | Description |
|-----------|------|-------------|
| `mcp_transport` | task | Top-level request handler |
| `tool_execution:<toolName>` | task | V1 API tool execution |
| `static_tool:<toolName>` | task | V2 API static tool (enable, disable, discover, execute, list) |
| `zapier_virtual_action:<name>` | task | Virtual actions (list_zaps, get_zap) |

### Available Metadata Fields (MCP)

- `metadata.environment` — `production`, `preview`, `development`, `test`
- `metadata.serverId` — MCP server UUID
- `metadata.accountId` — Zapier account ID
- `metadata.userId` — User UUID
- `metadata.transport` — `streamable-http` or `sse`
- `metadata.apiVersion` — API version string

### Summary Metrics (shape => 'summary')

When using summary shape, `metrics` contains:

- `metrics.duration` — max span duration in seconds
- `metrics.llm_calls` / `metrics.tool_calls` — counts
- `metrics.llm_errors` / `metrics.tool_errors` / `metrics.errors` — error counts
- `metrics.total_tokens` / `metrics.prompt_tokens` / `metrics.completion_tokens`
- `metrics.estimated_cost` — USD
- `metrics.llm_duration` — total LLM time in seconds
- `metrics.time_to_first_token` — avg TTFT across LLM spans

## Common Queries

### Recent errors

```sql
SELECT id, created, error, metadata
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'summary')
WHERE error IS NOT NULL
ORDER BY created DESC
LIMIT 10
```

### Traces for a specific server

```sql
SELECT id, created, span_attributes.name, input, output, error
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'spans')
WHERE metadata.serverId = '<SERVER_ID>'
ORDER BY created DESC
LIMIT 20
```

### Slow requests (duration > N seconds)

```sql
SELECT id, created, metrics.duration, error, metadata.serverId
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'summary')
WHERE metrics.duration > 10
ORDER BY created DESC
LIMIT 10
```

### Search by input content

```sql
SELECT id, created, input, output, span_attributes.name
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'spans')
WHERE input MATCH 'search term'
ORDER BY created DESC
LIMIT 10
```

### Error rate over time

```sql
SELECT day(created) AS date,
  count(1) AS total,
  sum(metrics.errors > 0 ? 1 : 0) AS errored
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'summary')
WHERE created > now() - interval 7 day
GROUP BY 1
ORDER BY date DESC
```

### All spans in a specific trace

```sql
SELECT id, span_attributes.name, span_attributes.type, created, input, output, error
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'spans')
WHERE root_span_id = '<TRACE_ID>'
ORDER BY created ASC
```

### Tool execution breakdown

```sql
SELECT span_attributes.name, count(1) AS calls, avg(metrics.duration) AS avg_duration
FROM project_logs('f4078417-106e-4a78-90bf-a97bd9f4d62f', shape => 'spans')
WHERE created > now() - interval 1 day
  AND span_attributes.name LIKE 'static_tool:%'
GROUP BY 1
ORDER BY calls DESC
```

## Workflow

1. **Understand what James is looking for** — errors? slow requests? specific user? specific tool?
2. **Build and run the BTQL query** — start with summary shape for overview, drill into spans shape for detail
3. **Present results clearly** — summarize findings, highlight errors and anomalies
4. **Drill deeper if needed** — use trace IDs from initial results to fetch full span trees

### Debugging a specific issue

1. Start broad: find matching traces via summary shape
2. Pick a trace ID from results
3. Fetch all spans for that trace to see the full execution flow
4. Examine input/output/error at each span level

## Time Filters

- `WHERE created > now() - interval 1 hour` — last hour
- `WHERE created > now() - interval 1 day` — last 24h
- `WHERE created > now() - interval 7 day` — last week
- `WHERE created > '2026-02-09T00:00:00Z'` — since specific time

## Notes

- Always pipe curl output through `python3 -m json.tool` for readability
- Use `LIMIT` generously — production data is high volume
- **Always include a time window** (`WHERE created > now() - interval 1 day`) on summary queries. Without it, queries scan all historical data and time out.
- The `input` and `output` fields can be large (full MCP payloads). Select specific fields when possible.
- For full-text search use `MATCH` (word-level). For pattern matching use `ILIKE '%pattern%'`.
- `MATCH` is faster but requires exact word matches. `ILIKE` is slower but matches substrings.
