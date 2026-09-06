#!/usr/bin/env node

import { Command } from "commander";
import { config } from "dotenv";
import { writeFileSync, readFileSync, mkdirSync, existsSync } from "fs";
import { dirname } from "path";
import { DatabricksClient } from "./api.js";
import {
  formatUser,
  formatCatalogsAsTable,
  formatSchemasAsTable,
  formatTablesAsTable,
  formatTableDetails,
  formatQueryResult,
  formatDashboardsAsTable,
  formatDashboardDetails,
  formatWarehousesAsTable,
  formatAsyncQueryResult,
} from "./formatter.js";
import type { ChartType } from "./types.js";

// Load environment variables
config();

const program = new Command();

program
  .name("databricks")
  .description(
    "CLI tool for Databricks operations - Unity Catalog and SQL queries",
  )
  .version("1.0.0");

function getClient(): DatabricksClient {
  const host = process.env.DATABRICKS_HOST;
  const token = process.env.DATABRICKS_TOKEN;
  const warehouseId = process.env.DATABRICKS_SQL_WAREHOUSE_ID;

  if (!host || !token) {
    console.error(
      "Error: DATABRICKS_HOST and DATABRICKS_TOKEN environment variables are required",
    );
    console.error("");
    console.error("Set them in your environment or create a .env file:");
    console.error(
      "  DATABRICKS_HOST=https://your-workspace.cloud.databricks.com",
    );
    console.error("  DATABRICKS_TOKEN=your-access-token");
    console.error("  DATABRICKS_SQL_WAREHOUSE_ID=your-warehouse-id");
    console.error("");
    console.error(
      "Get your access token at: https://dbc-37d560c2-40fd.cloud.databricks.com/settings/user/developer/access-tokens",
    );
    process.exit(1);
  }

  if (!warehouseId) {
    console.error(
      "Warning: DATABRICKS_SQL_WAREHOUSE_ID not set. SQL query commands will fail.",
    );
  }

  return new DatabricksClient(host, token, warehouseId || "");
}

function writeOutput(output: string, outputPath?: string): void {
  if (outputPath) {
    const dir = dirname(outputPath);
    if (dir && !existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }
    writeFileSync(outputPath, output);
    console.error(`Written to: ${outputPath}`);
  } else {
    console.log(output);
  }
}

// ============ WHOAMI ============
program
  .command("whoami")
  .description("Verify authentication and show current user")
  .action(async () => {
    try {
      const client = getClient();
      console.error("Verifying authentication...");

      const user = await client.getCurrentUser();
      console.log(formatUser(user));
    } catch (error) {
      console.error(
        "Authentication failed:",
        error instanceof Error ? error.message : error,
      );
      console.error("");
      console.error("Check your DATABRICKS_TOKEN in .env file or environment.");
      process.exit(1);
    }
  });

// ============ WAREHOUSES ============
program
  .command("warehouses")
  .description("List all SQL warehouses")
  .option("-f, --format <format>", "Output format (table|json)", "table")
  .option("-o, --output <path>", "Output file path")
  .action(async (options) => {
    try {
      const client = getClient();
      console.error("Fetching warehouses...");

      const warehouses = await client.listWarehouses();
      console.error(`Found ${warehouses.length} warehouses`);

      const output =
        options.format === "json"
          ? JSON.stringify(warehouses, null, 2)
          : formatWarehousesAsTable(warehouses);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ QUERY ASYNC ============
program
  .command("query-async [sql]")
  .description("Submit a SQL query asynchronously (returns statement ID)")
  .option("-i, --input <path>", "Read SQL from file")
  .action(async (sql, options) => {
    try {
      const client = getClient();

      // Get SQL from argument or file
      let query = sql;
      if (options.input) {
        if (!existsSync(options.input)) {
          console.error(`Error: File not found: ${options.input}`);
          process.exit(1);
        }
        query = readFileSync(options.input, "utf-8");
      }

      if (!query) {
        console.error("Error: Provide SQL as argument or use --input <file>");
        process.exit(1);
      }

      console.error("Submitting query...");
      const result = await client.submitQueryAsync(query);

      console.log(formatAsyncQueryResult(result));
      console.error("");
      console.error(`Use: databricks status ${result.statement_id}`);
      console.error(`Use: databricks results ${result.statement_id}`);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ STATUS ============
program
  .command("status <statementId>")
  .description("Check the status of an async query")
  .action(async (statementId) => {
    try {
      const client = getClient();
      console.error(`Checking status for ${statementId}...`);

      const result = await client.getStatementStatus(statementId);
      console.log(formatAsyncQueryResult(result));
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ RESULTS ============
program
  .command("results <statementId>")
  .description("Fetch results for a completed async query")
  .option(
    "-f, --format <format>",
    "Output format (table|json|jsonl|csv)",
    "table",
  )
  .option("-o, --output <path>", "Output file path")
  .action(async (statementId, options) => {
    try {
      const client = getClient();
      console.error(`Fetching results for ${statementId}...`);

      const result = await client.getStatementResults(statementId);

      if (result.status !== "success") {
        console.error(`Query not ready: ${result.error}`);
        if (result.details) {
          console.error(`Details: ${result.details}`);
        }
        process.exit(1);
      }

      console.error(`Returned ${result.rowCount} rows`);

      const output = formatQueryResult(result, options.format);
      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ CATALOGS ============
program
  .command("catalogs")
  .description("List all Unity Catalog catalogs")
  .option("-f, --format <format>", "Output format (table|json)", "table")
  .option("-o, --output <path>", "Output file path")
  .action(async (options) => {
    try {
      const client = getClient();
      console.error("Fetching catalogs...");

      const catalogs = await client.listCatalogs();
      console.error(`Found ${catalogs.length} catalogs`);

      const output =
        options.format === "json"
          ? JSON.stringify(catalogs, null, 2)
          : formatCatalogsAsTable(catalogs);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ SCHEMAS ============
program
  .command("schemas <catalog>")
  .description("List schemas in a catalog")
  .option("-f, --format <format>", "Output format (table|json)", "table")
  .option("-o, --output <path>", "Output file path")
  .action(async (catalog, options) => {
    try {
      const client = getClient();
      console.error(`Fetching schemas in ${catalog}...`);

      const schemas = await client.listSchemas(catalog);
      console.error(`Found ${schemas.length} schemas`);

      const output =
        options.format === "json"
          ? JSON.stringify(schemas, null, 2)
          : formatSchemasAsTable(schemas);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ TABLES ============
program
  .command("tables <catalog> <schema>")
  .description("List tables in a schema")
  .option("-f, --format <format>", "Output format (table|json)", "table")
  .option("-o, --output <path>", "Output file path")
  .action(async (catalog, schema, options) => {
    try {
      const client = getClient();
      console.error(`Fetching tables in ${catalog}.${schema}...`);

      const tables = await client.listTables(catalog, schema);
      console.error(`Found ${tables.length} tables`);

      const output =
        options.format === "json"
          ? JSON.stringify(tables, null, 2)
          : formatTablesAsTable(tables);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DESCRIBE ============
program
  .command("describe <table>")
  .description("Describe a table (use full name: catalog.schema.table)")
  .option("-f, --format <format>", "Output format (markdown|json)", "markdown")
  .option("-o, --output <path>", "Output file path")
  .action(async (table, options) => {
    try {
      const client = getClient();
      console.error(`Fetching table details for ${table}...`);

      const tableInfo = await client.getTable(table);

      const output =
        options.format === "json"
          ? JSON.stringify(tableInfo, null, 2)
          : formatTableDetails(tableInfo);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ QUERY ============
program
  .command("query [sql]")
  .description("Execute a SQL query")
  .option(
    "-f, --format <format>",
    "Output format (table|json|jsonl|csv)",
    "table",
  )
  .option("-o, --output <path>", "Output file path")
  .option("-i, --input <path>", "Read SQL from file")
  .option("-t, --timeout <seconds>", "Query timeout in seconds", "50")
  .action(async (sql, options) => {
    try {
      const client = getClient();

      // Get SQL from argument or file
      let query = sql;
      if (options.input) {
        if (!existsSync(options.input)) {
          console.error(`Error: File not found: ${options.input}`);
          process.exit(1);
        }
        query = readFileSync(options.input, "utf-8");
      }

      if (!query) {
        console.error("Error: Provide SQL as argument or use --input <file>");
        process.exit(1);
      }

      console.error("Executing query...");
      const timeout = `${options.timeout}s`;
      const result = await client.executeQuery(query, timeout);

      if (result.status !== "success") {
        console.error(`Query failed: ${result.error}`);
        if (result.details) {
          console.error(`Details: ${result.details}`);
        }
        process.exit(1);
      }

      console.error(`Returned ${result.rowCount} rows`);

      const output = formatQueryResult(result, options.format);
      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ SAMPLE ============
program
  .command("sample <table>")
  .description("Get sample rows from a table")
  .option("-n, --limit <number>", "Number of rows to sample", "10")
  .option(
    "-f, --format <format>",
    "Output format (table|json|jsonl|csv)",
    "table",
  )
  .option("-o, --output <path>", "Output file path")
  .action(async (table, options) => {
    try {
      const client = getClient();
      const limit = parseInt(options.limit, 10);
      const sql = `SELECT * FROM ${table} LIMIT ${limit}`;

      console.error(`Sampling ${limit} rows from ${table}...`);
      const result = await client.executeQuery(sql);

      if (result.status !== "success") {
        console.error(`Query failed: ${result.error}`);
        if (result.details) {
          console.error(`Details: ${result.details}`);
        }
        process.exit(1);
      }

      console.error(`Returned ${result.rowCount} rows`);

      const output = formatQueryResult(result, options.format);
      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARDS LIST ============
program
  .command("dashboards")
  .description("List all AI/BI dashboards")
  .option("-f, --format <format>", "Output format (table|json)", "table")
  .option("-o, --output <path>", "Output file path")
  .action(async (options) => {
    try {
      const client = getClient();
      console.error("Fetching dashboards...");

      const dashboards = await client.listDashboards();
      console.error(`Found ${dashboards.length} dashboards`);

      const output =
        options.format === "json"
          ? JSON.stringify(dashboards, null, 2)
          : formatDashboardsAsTable(dashboards);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARD GET ============
program
  .command("dashboard <id>")
  .description("Get dashboard details")
  .option("-f, --format <format>", "Output format (markdown|json)", "markdown")
  .option("-o, --output <path>", "Output file path")
  .action(async (id, options) => {
    try {
      const client = getClient();
      console.error(`Fetching dashboard ${id}...`);

      const dashboard = await client.getDashboard(id);

      const output =
        options.format === "json"
          ? JSON.stringify(dashboard, null, 2)
          : formatDashboardDetails(dashboard);

      writeOutput(output, options.output);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARD CREATE ============
program
  .command("dashboard-create")
  .description("Create a new AI/BI dashboard with a chart")
  .requiredOption("-n, --name <name>", "Dashboard name")
  .requiredOption("-s, --sql <sql>", "SQL query for the dataset")
  .requiredOption(
    "-c, --chart <type>",
    "Chart type (bar|line|area|scatter|pie|table|counter)",
  )
  .requiredOption("-x, --x-column <column>", "Column for x-axis or categories")
  .requiredOption(
    "-y, --y-columns <columns>",
    "Comma-separated columns for y-axis values",
  )
  .action(async (options) => {
    try {
      const client = getClient();
      console.error(`Creating dashboard "${options.name}"...`);

      const yColumns = options.yColumns.split(",").map((c: string) => c.trim());

      const result = await client.createDashboard(
        options.name,
        options.sql,
        options.chart as ChartType,
        options.xColumn,
        yColumns,
      );

      console.log(`Created: ${result.dashboard_id}`);
      console.log(`URL: ${result.url}`);
      console.log("");
      console.log(
        "Note: Dashboard is in draft state. Use 'dashboard-publish' to make it viewable.",
      );
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARD ADD CHART ============
program
  .command("dashboard-add-chart <dashboardId>")
  .description("Add a chart to an existing dashboard")
  .requiredOption("-n, --name <name>", "Chart name")
  .requiredOption("-s, --sql <sql>", "SQL query for the dataset")
  .requiredOption(
    "-c, --chart <type>",
    "Chart type (bar|line|area|scatter|pie|table|counter)",
  )
  .requiredOption("-x, --x-column <column>", "Column for x-axis or categories")
  .requiredOption(
    "-y, --y-columns <columns>",
    "Comma-separated columns for y-axis values",
  )
  .action(async (dashboardId, options) => {
    try {
      const client = getClient();
      console.error(
        `Adding chart "${options.name}" to dashboard ${dashboardId}...`,
      );

      const yColumns = options.yColumns.split(",").map((c: string) => c.trim());

      const result = await client.addChart(
        dashboardId,
        options.name,
        options.sql,
        options.chart as ChartType,
        options.xColumn,
        yColumns,
      );

      console.log(`Chart added to: ${result.dashboard_id}`);
      console.log(`URL: ${result.url}`);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARD UPDATE SQL ============
program
  .command("dashboard-update-sql <dashboardId>")
  .description("Update the SQL query for a dataset in a dashboard")
  .requiredOption(
    "-d, --dataset <name>",
    "Dataset name (use 'main_dataset' for single-chart dashboards)",
  )
  .requiredOption("-s, --sql <sql>", "New SQL query")
  .action(async (dashboardId, options) => {
    try {
      const client = getClient();
      console.error(
        `Updating SQL for dataset "${options.dataset}" in dashboard ${dashboardId}...`,
      );

      await client.updateDashboardSql(
        dashboardId,
        options.dataset,
        options.sql,
      );

      console.log(`Updated dataset: ${options.dataset}`);
      console.log(
        `Dashboard URL: ${client["host"]}/sql/dashboardsv3/${dashboardId}`,
      );
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARD PUBLISH ============
program
  .command("dashboard-publish <dashboardId>")
  .description("Publish a draft dashboard to make it viewable")
  .action(async (dashboardId) => {
    try {
      const client = getClient();
      console.error(`Publishing dashboard ${dashboardId}...`);

      const result = await client.publishDashboard(dashboardId);

      console.log(`Published: ${dashboardId}`);
      console.log(`URL: ${result.url}`);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

// ============ DASHBOARD DELETE ============
program
  .command("dashboard-delete <dashboardId>")
  .description("Delete a dashboard (moves to trash)")
  .action(async (dashboardId) => {
    try {
      const client = getClient();
      console.error(`Deleting dashboard ${dashboardId}...`);

      await client.deleteDashboard(dashboardId);

      console.log(`Deleted: ${dashboardId}`);
    } catch (error) {
      console.error("Error:", error instanceof Error ? error.message : error);
      process.exit(1);
    }
  });

program.parse();
