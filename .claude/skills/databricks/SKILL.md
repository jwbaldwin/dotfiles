---
name: databricks
description: Query Databricks, explore Unity Catalog, and manage AI/BI dashboards. Triggered by "databricks", "check databricks", "query data", "run query", or "check databricks".
allowed-tools: 
  - read
  - write
  - edit
  - bash
  - glob
---

# Databricks

Query Zapier's Databricks warehouse, explore Unity Catalog, and manage AI/BI dashboards via a local CLI tool.

## Config

| Key | Value |
|-----|-------|
| Skill directory | `~/.config/opencode/skills/databricks` |
| Host | `https://dbc-37d560c2-40fd.cloud.databricks.com` |
| Warehouse ID | `24ca15a1207d8b4a` |
| Token page | `https://dbc-37d560c2-40fd.cloud.databricks.com/settings/user/developer/access-tokens` |

**Requires Zapier VPN (Viscosity) for all commands.**

## Credentials & CLI

The CLI tool and `.env` credentials both live in this skill directory (`~/.config/opencode/skills/databricks`). Self-contained — no external repo dependency.

If the `.env` is missing or the token is expired, tell James — do NOT create it or guess the token value.

## Setup (one-time)

Before first use, check that deps are installed:

```bash
# Install deps if node_modules is missing
pnpm install   # workdir: ~/.config/opencode/skills/databricks
```

## Running Commands

All commands are run from this skill directory. The `.env` is loaded automatically by dotenv since it's in the working directory.

```bash
pnpm run databricks <command>
```

When using the Bash tool, always set `workdir` to `/Users/jbaldwin/.config/opencode/skills/databricks`.

## Commands Reference

### Authentication

```bash
pnpm run databricks whoami
```

### Unity Catalog Exploration

```bash
# List catalogs
pnpm run databricks catalogs

# List schemas in a catalog
pnpm run databricks schemas <catalog>
# Example: pnpm run databricks schemas public
# Example: pnpm run databricks schemas production_refined

# List tables in a schema
pnpm run databricks tables <catalog> <schema>
# Example: pnpm run databricks tables public db_zapier
# Example: pnpm run databricks tables production_refined events

# Describe a table (full name: catalog.schema.table)
pnpm run databricks describe <catalog.schema.table>
# Example: pnpm run databricks describe public.fact_zap_usage
# Example: pnpm run databricks describe production_refined.db_zapier.flow_node
```

### SQL Queries

```bash
# Run a query (default output: markdown table)
pnpm run databricks query "SELECT COUNT(*) FROM public.dim_account_current"

# Output formats: table (default), json, jsonl, csv
pnpm run databricks query "SELECT * FROM public.dim_plan LIMIT 5" -f json

# Save to file
pnpm run databricks query "SELECT * FROM public.dim_plan" -o results.json -f json

# Read SQL from file
pnpm run databricks query -i query.sql -o results.csv -f csv

# Custom timeout (default 50s)
pnpm run databricks query "SELECT * FROM large_table" -t 120
```

### Async Queries (long-running)

```bash
# Submit and get statement ID back immediately
pnpm run databricks query-async "SELECT * FROM huge_table"

# Check status
pnpm run databricks status <statement-id>

# Fetch results when done
pnpm run databricks results <statement-id> -f json
```

### Sample Data

```bash
# Quick sample (default 10 rows)
pnpm run databricks sample public.dim_account_current

# Custom row count
pnpm run databricks sample public.fact_zap_usage -n 50

# Different format
pnpm run databricks sample public.dim_plan -n 5 -f json
```

### SQL Warehouses

```bash
pnpm run databricks warehouses
```

### AI/BI Dashboards

```bash
# List dashboards
pnpm run databricks dashboards

# Get dashboard details (datasets, SQL, charts)
pnpm run databricks dashboard <dashboard-id>

# Create dashboard with a chart
pnpm run databricks dashboard-create \
  -n "Dashboard Name" \
  -s "SELECT date, COUNT(*) as count FROM table GROUP BY date" \
  -c line -x date -y count

# Add chart to existing dashboard
pnpm run databricks dashboard-add-chart <dashboard-id> \
  -n "Chart Name" \
  -s "SELECT month, SUM(revenue) as total FROM sales GROUP BY month" \
  -c bar -x month -y total

# Update SQL for a dataset
pnpm run databricks dashboard-update-sql <dashboard-id> \
  -d main_dataset -s "SELECT new_query FROM ..."

# Publish (make viewable)
pnpm run databricks dashboard-publish <dashboard-id>

# Delete (moves to trash)
pnpm run databricks dashboard-delete <dashboard-id>
```

**Chart types:** `bar`, `line`, `area`, `scatter`, `pie`, `table`, `counter`

## Output Formats

| Format | Flag | Use case |
|--------|------|----------|
| `table` | `-f table` (default) | Viewing in terminal, markdown tables |
| `json` | `-f json` | Pretty-printed, good for inspection |
| `jsonl` | `-f jsonl` | Large exports, one object per line |
| `csv` | `-f csv` | Spreadsheet-friendly |

## Workflow

### Exploring data James doesn't know the shape of

1. Start with `catalogs` to see what's available
2. Drill into `schemas <catalog>` for a relevant catalog
3. List `tables <catalog> <schema>` to find relevant tables
4. `describe <catalog.schema.table>` to see columns and types
5. `sample <table> -n 5` to see actual data
6. Write and run the actual query

### Answering a data question

1. If James names specific tables, skip to querying
2. If not, explore the catalog to find relevant tables
3. Describe tables to understand columns
4. Sample a few rows to understand data shape
5. Write the SQL query
6. Run it, present results clearly
7. If James wants a dashboard, create one from the query

### Building a dashboard

1. Get or write the SQL query first
2. Run the query to verify it works
3. `dashboard-create` with the query and appropriate chart type
4. `dashboard-publish` to make it viewable
5. Share the URL with James

### Large/slow queries

1. Use `query-async` to submit without blocking
2. Poll `status <id>` until SUCCEEDED
3. Fetch with `results <id> -f json`
4. Or just increase timeout: `query "..." -t 300`

## Key Zapier Catalogs

| Catalog | Description |
|---------|-------------|
| `public` | Main analytics tables (dim/fact tables) |
| `production_refined` | Refined production data |

Common tables to know about:
- `public.dim_account_current` — Account dimension
- `public.dim_plan` — Plan information
- `public.fact_zap_usage` — Zap usage facts

Use `describe` to find more — don't guess column names.

## Troubleshooting

| Error | Fix |
|-------|-----|
| "DATABRICKS_HOST and DATABRICKS_TOKEN environment variables are required" | `.env` missing from skill directory. James needs to create it. |
| "Databricks API error (401)" | Token expired. James needs a new one from the token page. |
| "Databricks API error (403)" | Check VPN is connected. Check token permissions. |
| Query timeout | Increase timeout with `-t 300` or use `query-async`. |
| Connection refused / network error | VPN not connected (Viscosity). |
