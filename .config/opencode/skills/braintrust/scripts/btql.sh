#!/usr/bin/env bash
# Query Braintrust via BTQL (SQL-like queries against production traces)
#
# Usage:
#   btql.sh "SELECT id, created FROM project_logs('PROJECT_ID') LIMIT 5"
#   btql.sh --project mcp "SELECT * FROM {{PROJECT}} LIMIT 5"
#   btql.sh --errors                     # Recent errors (MCP)
#   btql.sh --errors --limit 20          # More errors
#   btql.sh --slow 10                    # Traces slower than 10s
#   btql.sh --trace <TRACE_ID>           # All spans in a trace
#   btql.sh --server <SERVER_ID>         # Traces for a server
#   btql.sh --search "term"              # Full-text search on input
#   btql.sh --tools                      # Tool execution breakdown (24h)
#   btql.sh --raw '{"query":"...","fmt":"json"}'  # Raw JSON body

set -euo pipefail

BTQL_URL="https://d30590cgs91ici.cloudfront.net/btql"

# Project IDs
MCP_PROJECT="f4078417-106e-4a78-90bf-a97bd9f4d62f"
CORE_PROJECT="41d8234a-0127-4c9d-a39a-348705066ccf"
AIQUERY_PROJECT="8f99eacc-bdaa-4f39-a4bc-797d114f82fe"

# Default project
PROJECT="$MCP_PROJECT"
LIMIT=10
FMT="json"

if [ -z "${BRAINTRUST_API_KEY:-}" ]; then
  echo "Error: BRAINTRUST_API_KEY not set" >&2
  exit 1
fi

run_query() {
  local query="$1"
  curl -s --max-time 30 -X POST "$BTQL_URL" \
    -H "Authorization: Bearer $BRAINTRUST_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"query\": $(echo "$query" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'), \"fmt\": \"$FMT\"}" \
    | python3 -m json.tool 2>/dev/null || cat
}

run_raw() {
  local body="$1"
  curl -s --max-time 30 -X POST "$BTQL_URL" \
    -H "Authorization: Bearer $BRAINTRUST_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body" \
    | python3 -m json.tool 2>/dev/null || cat
}

# Parse args
MODE=""
VALUE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      case "$2" in
        mcp)      PROJECT="$MCP_PROJECT" ;;
        core)     PROJECT="$CORE_PROJECT" ;;
        aiquery)  PROJECT="$AIQUERY_PROJECT" ;;
        *)        PROJECT="$2" ;;
      esac
      shift 2 ;;
    --limit)    LIMIT="$2"; shift 2 ;;
    --fmt)      FMT="$2"; shift 2 ;;
    --errors)   MODE="errors"; shift ;;
    --slow)     MODE="slow"; VALUE="${2:-10}"; shift; [[ "${1:-}" =~ ^[0-9]+$ ]] && shift || true ;;
    --trace)    MODE="trace"; VALUE="$2"; shift 2 ;;
    --server)   MODE="server"; VALUE="$2"; shift 2 ;;
    --search)   MODE="search"; VALUE="$2"; shift 2 ;;
    --tools)    MODE="tools"; shift ;;
    --raw)      MODE="raw"; VALUE="$2"; shift 2 ;;
    *)
      # Bare argument = raw SQL query
      if [ -z "$MODE" ]; then
        MODE="sql"
        VALUE="$1"
      fi
      shift ;;
  esac
done

# Replace {{PROJECT}} placeholder in raw SQL
if [ "$MODE" = "sql" ]; then
  VALUE="${VALUE//\{\{PROJECT\}\}/project_logs(\'$PROJECT\', shape => \'spans\')}"
fi

case "$MODE" in
  errors)
    run_query "SELECT id, created, error, metadata.serverId, metadata.accountId FROM project_logs('$PROJECT', shape => 'summary') WHERE created > now() - interval 1 day AND error IS NOT NULL ORDER BY created DESC LIMIT $LIMIT"
    ;;
  slow)
    run_query "SELECT id, created, metrics.duration, error, metadata.serverId FROM project_logs('$PROJECT', shape => 'summary') WHERE created > now() - interval 1 day AND metrics.duration > $VALUE ORDER BY metrics.duration DESC LIMIT $LIMIT"
    ;;
  trace)
    run_query "SELECT id, span_attributes.name, span_attributes.type, created, input, output, error FROM project_logs('$PROJECT', shape => 'spans') WHERE root_span_id = '$VALUE' ORDER BY created ASC"
    ;;
  server)
    run_query "SELECT id, created, span_attributes.name, error, metadata FROM project_logs('$PROJECT', shape => 'spans') WHERE metadata.serverId = '$VALUE' ORDER BY created DESC LIMIT $LIMIT"
    ;;
  search)
    run_query "SELECT id, created, span_attributes.name, input, output FROM project_logs('$PROJECT', shape => 'spans') WHERE input MATCH '$VALUE' ORDER BY created DESC LIMIT $LIMIT"
    ;;
  tools)
    run_query "SELECT span_attributes.name, count(1) AS calls FROM project_logs('$PROJECT', shape => 'spans') WHERE created > now() - interval 1 day AND span_attributes.name LIKE 'static_tool:%' GROUP BY 1 ORDER BY calls DESC"
    ;;
  raw)
    run_raw "$VALUE"
    ;;
  sql)
    run_query "$VALUE"
    ;;
  *)
    echo "Usage: btql.sh [OPTIONS] [SQL_QUERY]"
    echo ""
    echo "Quick commands:"
    echo "  --errors              Recent error traces"
    echo "  --slow [seconds]      Slow traces (default: >10s)"
    echo "  --trace <ID>          All spans in a trace"
    echo "  --server <ID>         Traces for a server"
    echo "  --search \"term\"       Full-text search on input"
    echo "  --tools               Tool execution breakdown (24h)"
    echo ""
    echo "Options:"
    echo "  --project mcp|core|aiquery|<ID>  Select project (default: mcp)"
    echo "  --limit N                        Result limit (default: 10)"
    echo "  --fmt json|parquet               Output format (default: json)"
    echo "  --raw '{...}'                    Raw JSON body"
    echo ""
    echo "SQL query:"
    echo "  btql.sh \"SELECT * FROM project_logs('ID') LIMIT 5\""
    ;;
esac
