import type {
  CatalogInfo,
  SchemaInfo,
  TableInfo,
  ColumnInfo,
  QueryResult,
  CurrentUser,
  DashboardInfo,
  ParsedDashboard,
  WarehouseInfo,
  AsyncQueryResult,
} from "./types.js";

// ============ User Formatting ============

export function formatUser(user: CurrentUser): string {
  const lines: string[] = [];
  lines.push(`User: ${user.displayName}`);
  lines.push(`Username: ${user.userName}`);
  if (user.emails?.length) {
    const primary = user.emails.find((e) => e.primary) || user.emails[0];
    lines.push(`Email: ${primary.value}`);
  }
  lines.push(`ID: ${user.id}`);
  lines.push(`Active: ${user.active}`);
  return lines.join("\n");
}

// ============ Warehouse Formatting ============

export function formatWarehousesAsTable(warehouses: WarehouseInfo[]): string {
  if (warehouses.length === 0) {
    return "No warehouses found.";
  }

  const lines: string[] = [];
  lines.push("| Name | ID | State | Size | Auto Stop |");
  lines.push("|------|-----|-------|------|-----------|");

  for (const wh of warehouses) {
    const autoStop = wh.auto_stop_mins ? `${wh.auto_stop_mins} mins` : "-";
    lines.push(
      `| ${wh.name} | ${wh.id} | ${wh.state} | ${wh.cluster_size || "-"} | ${autoStop} |`,
    );
  }

  lines.push("");
  lines.push(`Total: ${warehouses.length} warehouses`);
  return lines.join("\n");
}

// ============ Async Query Formatting ============

export function formatAsyncQueryResult(result: AsyncQueryResult): string {
  const lines: string[] = [];
  lines.push(`Statement ID: ${result.statement_id}`);
  lines.push(`State: ${result.state}`);
  if (result.error) {
    lines.push(`Error: ${result.error}`);
  }
  return lines.join("\n");
}

// ============ Catalog Formatting ============

export function formatCatalogsAsTable(catalogs: CatalogInfo[]): string {
  if (catalogs.length === 0) {
    return "No catalogs found.";
  }

  const lines: string[] = [];
  lines.push("| Catalog | Type | Description |");
  lines.push("|---------|------|-------------|");

  for (const catalog of catalogs) {
    const desc = catalog.comment || "-";
    const type = catalog.catalog_type || "-";
    lines.push(`| ${catalog.name} | ${type} | ${truncate(desc, 50)} |`);
  }

  lines.push("");
  lines.push(`Total: ${catalogs.length} catalogs`);
  return lines.join("\n");
}

// ============ Schema Formatting ============

export function formatSchemasAsTable(schemas: SchemaInfo[]): string {
  if (schemas.length === 0) {
    return "No schemas found.";
  }

  const lines: string[] = [];
  lines.push("| Schema | Description |");
  lines.push("|--------|-------------|");

  for (const schema of schemas) {
    const desc = schema.comment || "-";
    lines.push(`| ${schema.name} | ${truncate(desc, 60)} |`);
  }

  lines.push("");
  lines.push(`Total: ${schemas.length} schemas`);
  return lines.join("\n");
}

// ============ Table Formatting ============

export function formatTablesAsTable(tables: TableInfo[]): string {
  if (tables.length === 0) {
    return "No tables found.";
  }

  const lines: string[] = [];
  lines.push("| Table | Type | Description |");
  lines.push("|-------|------|-------------|");

  for (const table of tables) {
    const desc = table.comment || "-";
    lines.push(
      `| ${table.name} | ${table.table_type} | ${truncate(desc, 50)} |`,
    );
  }

  lines.push("");
  lines.push(`Total: ${tables.length} tables`);
  return lines.join("\n");
}

export function formatTableDetails(table: TableInfo): string {
  const lines: string[] = [];

  lines.push(`# Table: ${table.full_name}`);
  lines.push("");

  if (table.comment) {
    lines.push(`**Description:** ${table.comment}`);
    lines.push("");
  }

  lines.push(`**Type:** ${table.table_type}`);
  if (table.owner) {
    lines.push(`**Owner:** ${table.owner}`);
  }
  lines.push("");

  // Partition columns
  const partitionCols = table.columns?.filter(
    (c) => c.partition_index !== undefined && c.partition_index !== null,
  );
  if (partitionCols && partitionCols.length > 0) {
    lines.push("## Partition Columns");
    partitionCols
      .sort((a, b) => (a.partition_index || 0) - (b.partition_index || 0))
      .forEach((col) => {
        lines.push(`- \`${col.name}\``);
      });
    lines.push("");
  }

  // Columns
  if (table.columns && table.columns.length > 0) {
    lines.push("## Columns");
    lines.push("");
    lines.push("| Column | Type | Nullable | Description |");
    lines.push("|--------|------|----------|-------------|");

    for (const col of table.columns) {
      const nullable = col.nullable ? "Yes" : "No";
      const desc = col.comment || "-";
      lines.push(
        `| ${col.name} | ${col.type_text || col.type_name} | ${nullable} | ${truncate(desc, 40)} |`,
      );
    }
  } else {
    lines.push("*No column information available.*");
  }

  return lines.join("\n");
}

// ============ Query Result Formatting ============

export function formatQueryResult(
  result: QueryResult,
  format: "table" | "json" | "jsonl" | "csv" = "table",
): string {
  if (result.status !== "success") {
    return `Error: ${result.error}${result.details ? `\nDetails: ${result.details}` : ""}`;
  }

  if (!result.data || result.data.length === 0) {
    return "Query succeeded but returned no data.";
  }

  switch (format) {
    case "json":
      return JSON.stringify(result.data, null, 2);

    case "jsonl":
      return result.data.map((row) => JSON.stringify(row)).join("\n");

    case "csv":
      return formatAsCsv(result.columns || [], result.data);

    case "table":
    default:
      return formatAsMarkdownTable(result.columns || [], result.data);
  }
}

function formatAsMarkdownTable(
  columns: string[],
  data: Array<Record<string, unknown>>,
): string {
  if (columns.length === 0) return "No columns in result.";

  const lines: string[] = [];

  // Header
  lines.push("| " + columns.join(" | ") + " |");
  lines.push("| " + columns.map(() => "---").join(" | ") + " |");

  // Limit rows for table display
  const maxRows = 100;
  const displayData = data.slice(0, maxRows);

  for (const row of displayData) {
    const values = columns.map((col) => {
      const val = row[col];
      if (val === null || val === undefined) return "NULL";
      if (typeof val === "object") return JSON.stringify(val);
      return String(val);
    });
    lines.push("| " + values.map((v) => truncate(v, 50)).join(" | ") + " |");
  }

  if (data.length > maxRows) {
    lines.push("");
    lines.push(
      `... and ${data.length - maxRows} more rows (${data.length} total)`,
    );
  } else {
    lines.push("");
    lines.push(`${data.length} rows`);
  }

  return lines.join("\n");
}

function formatAsCsv(
  columns: string[],
  data: Array<Record<string, unknown>>,
): string {
  const lines: string[] = [];

  // Header
  lines.push(columns.map(escapeCsvField).join(","));

  // Data rows
  for (const row of data) {
    const values = columns.map((col) => {
      const val = row[col];
      if (val === null || val === undefined) return "";
      if (typeof val === "object") return JSON.stringify(val);
      return String(val);
    });
    lines.push(values.map(escapeCsvField).join(","));
  }

  return lines.join("\n");
}

function escapeCsvField(field: string): string {
  if (field.includes(",") || field.includes('"') || field.includes("\n")) {
    return `"${field.replace(/"/g, '""')}"`;
  }
  return field;
}

// ============ Dashboard Formatting ============

export function formatDashboardsAsTable(dashboards: DashboardInfo[]): string {
  if (dashboards.length === 0) {
    return "No dashboards found.";
  }

  const lines: string[] = [];
  lines.push("| Name | ID | State | Path |");
  lines.push("|------|-----|-------|------|");

  for (const dash of dashboards) {
    const state = dash.lifecycle_state || "-";
    const path = dash.parent_path || "-";
    lines.push(
      `| ${truncate(dash.display_name, 40)} | ${dash.dashboard_id} | ${state} | ${truncate(path, 30)} |`,
    );
  }

  lines.push("");
  lines.push(`Total: ${dashboards.length} dashboards`);
  return lines.join("\n");
}

export function formatDashboardDetails(dashboard: ParsedDashboard): string {
  const lines: string[] = [];

  lines.push(`# Dashboard: ${dashboard.name}`);
  lines.push("");
  lines.push(`**ID:** ${dashboard.dashboard_id}`);
  lines.push(`**State:** ${dashboard.lifecycle_state || "unknown"}`);
  if (dashboard.parent_path) {
    lines.push(`**Path:** ${dashboard.parent_path}`);
  }
  lines.push(`**URL:** ${dashboard.url}`);
  lines.push("");

  // Datasets
  lines.push("## Datasets");
  if (dashboard.datasets.length === 0) {
    lines.push("*No datasets*");
  } else {
    for (const ds of dashboard.datasets) {
      lines.push("");
      lines.push(`### ${ds.display_name || ds.name}`);
      if (ds.query) {
        lines.push("```sql");
        lines.push(ds.query.trim());
        lines.push("```");
      }
    }
  }

  lines.push("");

  // Charts
  lines.push("## Charts");
  if (dashboard.charts.length === 0) {
    lines.push("*No charts*");
  } else {
    lines.push("");
    lines.push("| Chart | Type | Dataset |");
    lines.push("|-------|------|---------|");
    for (const chart of dashboard.charts) {
      lines.push(
        `| ${chart.title || chart.name} | ${chart.chart_type || "-"} | ${chart.dataset || "-"} |`,
      );
    }
  }

  return lines.join("\n");
}

// ============ Utilities ============

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.substring(0, maxLen - 3) + "...";
}
