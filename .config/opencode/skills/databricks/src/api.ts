import type {
  CatalogInfo,
  SchemaInfo,
  TableInfo,
  StatementResponse,
  QueryResult,
  CurrentUser,
  ChartType,
  DashboardInfo,
  DashboardListResponse,
  DashboardDefinition,
  DashboardDataset,
  DashboardWidget,
  DashboardLayoutItem,
  DashboardPage,
  ParsedDashboard,
  WarehouseInfo,
  WarehouseListResponse,
  AsyncQueryResult,
} from "./types.js";

const SUPPORTED_CHART_TYPES: ChartType[] = [
  "bar",
  "line",
  "area",
  "scatter",
  "pie",
  "table",
  "counter",
];

export class DatabricksClient {
  private host: string;
  private token: string;
  private warehouseId: string;

  constructor(host: string, token: string, warehouseId: string) {
    // Remove trailing slash from host if present
    this.host = host.replace(/\/$/, "");
    this.token = token;
    this.warehouseId = warehouseId;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
    apiVersion: string = "2.1",
  ): Promise<T> {
    const url = `${this.host}/api/${apiVersion}${endpoint}`;

    const response = await fetch(url, {
      ...options,
      headers: {
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json",
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorBody = await response.text();
      let errorMessage: string;
      try {
        const errorJson = JSON.parse(errorBody);
        errorMessage = errorJson.message || errorJson.error || errorBody;
      } catch {
        errorMessage = errorBody;
      }
      throw new Error(
        `Databricks API error (${response.status}): ${errorMessage}`,
      );
    }

    return response.json() as Promise<T>;
  }

  // ============ User Info ============

  async getCurrentUser(): Promise<CurrentUser> {
    // SCIM API uses 2.0 prefix
    const url = `${this.host}/api/2.0/preview/scim/v2/Me`;
    const response = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this.token}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(
        `Databricks API error (${response.status}): ${errorBody}`,
      );
    }

    return response.json() as Promise<CurrentUser>;
  }

  // ============ SQL Warehouses ============

  async listWarehouses(): Promise<WarehouseInfo[]> {
    const result = await this.request<WarehouseListResponse>(
      "/sql/warehouses",
      {},
      "2.0",
    );
    return result.warehouses || [];
  }

  // ============ Async Query Operations ============

  async submitQueryAsync(sql: string): Promise<AsyncQueryResult> {
    const response = await this.request<StatementResponse>(
      "/sql/statements",
      {
        method: "POST",
        body: JSON.stringify({
          statement: sql,
          warehouse_id: this.warehouseId,
          wait_timeout: "0s", // Return immediately
        }),
      },
      "2.0",
    );

    return {
      statement_id: response.statement_id,
      state: response.status.state,
      error: response.status.error?.message,
    };
  }

  async getStatementStatus(statementId: string): Promise<AsyncQueryResult> {
    const response = await this.request<StatementResponse>(
      `/sql/statements/${statementId}`,
      {},
      "2.0",
    );

    return {
      statement_id: response.statement_id,
      state: response.status.state,
      error: response.status.error?.message,
    };
  }

  async getStatementResults(statementId: string): Promise<QueryResult> {
    const response = await this.request<StatementResponse>(
      `/sql/statements/${statementId}`,
      {},
      "2.0",
    );

    if (response.status.state !== "SUCCEEDED") {
      return {
        status: "failed",
        error: `Query not complete. State: ${response.status.state}`,
        details: response.status.error?.message,
      };
    }

    return this.parseStatementResponse(response);
  }

  // ============ Unity Catalog ============

  async listCatalogs(): Promise<CatalogInfo[]> {
    const result = await this.request<{ catalogs?: CatalogInfo[] }>(
      "/unity-catalog/catalogs",
    );
    return result.catalogs || [];
  }

  async listSchemas(catalogName: string): Promise<SchemaInfo[]> {
    const result = await this.request<{ schemas?: SchemaInfo[] }>(
      `/unity-catalog/schemas?catalog_name=${encodeURIComponent(catalogName)}`,
    );
    return result.schemas || [];
  }

  async listTables(
    catalogName: string,
    schemaName: string,
  ): Promise<TableInfo[]> {
    const result = await this.request<{ tables?: TableInfo[] }>(
      `/unity-catalog/tables?catalog_name=${encodeURIComponent(catalogName)}&schema_name=${encodeURIComponent(schemaName)}`,
    );
    return result.tables || [];
  }

  async getTable(fullTableName: string): Promise<TableInfo> {
    const result = await this.request<TableInfo>(
      `/unity-catalog/tables/${encodeURIComponent(fullTableName)}`,
    );
    return result;
  }

  // ============ SQL Execution ============

  async executeQuery(
    sql: string,
    waitTimeout: string = "50s",
  ): Promise<QueryResult> {
    try {
      const response = await this.request<StatementResponse>(
        "/sql/statements",
        {
          method: "POST",
          body: JSON.stringify({
            statement: sql,
            warehouse_id: this.warehouseId,
            wait_timeout: waitTimeout,
          }),
        },
        "2.0",
      );

      // Check if we need to poll for results
      if (
        response.status.state === "PENDING" ||
        response.status.state === "RUNNING"
      ) {
        return this.pollForResults(response.statement_id, 60000); // 60 second timeout
      }

      return this.parseStatementResponse(response);
    } catch (error) {
      return {
        status: "error",
        error:
          error instanceof Error ? error.message : "Unknown error during query",
      };
    }
  }

  private async pollForResults(
    statementId: string,
    timeoutMs: number,
  ): Promise<QueryResult> {
    const startTime = Date.now();
    const pollInterval = 1000; // 1 second

    while (Date.now() - startTime < timeoutMs) {
      const response = await this.request<StatementResponse>(
        `/sql/statements/${statementId}`,
        {},
        "2.0",
      );

      if (response.status.state === "SUCCEEDED") {
        return this.parseStatementResponse(response);
      }

      if (
        response.status.state === "FAILED" ||
        response.status.state === "CANCELED"
      ) {
        return {
          status: "failed",
          error: response.status.error?.message || "Query failed",
          details: response.status.error?.error_code,
        };
      }

      // Still running, wait before polling again
      await new Promise((resolve) => setTimeout(resolve, pollInterval));
    }

    return {
      status: "error",
      error: "Query timed out waiting for results",
    };
  }

  private parseStatementResponse(response: StatementResponse): QueryResult {
    if (response.status.state === "SUCCEEDED") {
      const columns =
        response.manifest?.schema?.columns?.map((c) => c.name) || [];
      const dataArray = response.result?.data_array || [];

      // Convert array of arrays to array of objects
      const data = dataArray.map((row) => {
        const obj: Record<string, unknown> = {};
        columns.forEach((col, i) => {
          obj[col] = row[i];
        });
        return obj;
      });

      return {
        status: "success",
        columns,
        data,
        rowCount: data.length,
      };
    }

    return {
      status: "failed",
      error: response.status.error?.message || "Query failed",
      details: response.status.error?.error_code,
    };
  }

  // ============ Query with Pagination ============

  async executeQueryWithChunks(
    sql: string,
    onChunk?: (chunk: QueryResult) => void,
  ): Promise<QueryResult> {
    // For now, just use the regular execute.
    // Databricks handles chunking internally for large results.
    const result = await this.executeQuery(sql);
    if (onChunk && result.status === "success") {
      onChunk(result);
    }
    return result;
  }

  // ============ Dashboard (Lakeview) Operations ============

  async listDashboards(): Promise<DashboardInfo[]> {
    const result = await this.request<DashboardListResponse>(
      "/lakeview/dashboards",
      {},
      "2.0",
    );
    return result.dashboards || [];
  }

  async getDashboard(dashboardId: string): Promise<ParsedDashboard> {
    const dashboard = await this.request<DashboardInfo>(
      `/lakeview/dashboards/${dashboardId}`,
      {},
      "2.0",
    );

    const parsed: ParsedDashboard = {
      dashboard_id: dashboard.dashboard_id,
      name: dashboard.display_name,
      parent_path: dashboard.parent_path,
      lifecycle_state: dashboard.lifecycle_state,
      url: `${this.host}/sql/dashboardsv3/${dashboard.dashboard_id}`,
      datasets: [],
      charts: [],
    };

    if (dashboard.serialized_dashboard) {
      try {
        const def: DashboardDefinition = JSON.parse(
          dashboard.serialized_dashboard,
        );

        // Extract datasets
        for (const ds of def.datasets || []) {
          let query = ds.query;
          if (!query && ds.queryLines) {
            query = ds.queryLines.join("");
          }
          parsed.datasets.push({
            name: ds.name,
            display_name: ds.displayName,
            query,
          });
        }

        // Extract charts from pages
        for (const page of def.pages || []) {
          for (const layoutItem of page.layout || []) {
            const widget = layoutItem.widget;
            if (!widget) continue;

            const queries = widget.queries || [];
            const datasetName = queries[0]?.query?.datasetName;
            const frame = widget.spec?.frame;

            parsed.charts.push({
              name: widget.name,
              title: frame?.title || widget.name,
              chart_type: widget.spec?.widgetType,
              page: page.displayName || page.name,
              dataset: datasetName,
            });
          }
        }
      } catch {
        // Ignore parse errors
      }
    }

    return parsed;
  }

  async createDashboard(
    name: string,
    sql: string,
    chartType: ChartType,
    xColumn: string,
    yColumns: string[],
  ): Promise<{ dashboard_id: string; url: string }> {
    if (!SUPPORTED_CHART_TYPES.includes(chartType)) {
      throw new Error(
        `Unsupported chart type '${chartType}'. Supported: ${SUPPORTED_CHART_TYPES.join(", ")}`,
      );
    }

    const datasetName = "main_dataset";
    const dataset = this.buildDataset(datasetName, sql);
    const widget = this.buildWidget(
      `${name}-chart`,
      datasetName,
      chartType,
      xColumn,
      yColumns,
      name,
    );
    const layoutItem = this.buildLayoutItem(widget, {
      x: 0,
      y: 0,
      width: 3,
      height: 6,
    });
    const page = this.buildPage("page-1", [layoutItem]);
    const serialized = JSON.stringify({ datasets: [dataset], pages: [page] });

    const result = await this.request<DashboardInfo>(
      "/lakeview/dashboards",
      {
        method: "POST",
        body: JSON.stringify({
          display_name: name,
          warehouse_id: this.warehouseId,
          serialized_dashboard: serialized,
        }),
      },
      "2.0",
    );

    return {
      dashboard_id: result.dashboard_id,
      url: `${this.host}/sql/dashboardsv3/${result.dashboard_id}`,
    };
  }

  async addChart(
    dashboardId: string,
    chartName: string,
    sql: string,
    chartType: ChartType,
    xColumn: string,
    yColumns: string[],
  ): Promise<{ dashboard_id: string; url: string }> {
    if (!SUPPORTED_CHART_TYPES.includes(chartType)) {
      throw new Error(
        `Unsupported chart type '${chartType}'. Supported: ${SUPPORTED_CHART_TYPES.join(", ")}`,
      );
    }

    // Get existing dashboard
    const existing = await this.request<DashboardInfo>(
      `/lakeview/dashboards/${dashboardId}`,
      {},
      "2.0",
    );

    const def: DashboardDefinition = existing.serialized_dashboard
      ? JSON.parse(existing.serialized_dashboard)
      : { datasets: [], pages: [] };

    // Generate unique dataset name
    const datasetName = `dataset_${def.datasets.length}`;

    // Add new dataset
    def.datasets.push(this.buildDataset(datasetName, sql));

    // Calculate position for new widget
    const existingLayout = def.pages?.[0]?.layout || [];
    let yPosition = 0;
    for (const item of existingLayout) {
      const bottom = (item.position?.y || 0) + (item.position?.height || 6);
      yPosition = Math.max(yPosition, bottom);
    }

    // Build new widget
    const widget = this.buildWidget(
      chartName.toLowerCase().replace(/ /g, "-"),
      datasetName,
      chartType,
      xColumn,
      yColumns,
      chartName,
    );
    const layoutItem = this.buildLayoutItem(widget, {
      x: 0,
      y: yPosition,
      width: 3,
      height: 6,
    });

    // Add to first page
    if (!def.pages.length) {
      def.pages.push(this.buildPage("page-1", [layoutItem]));
    } else {
      def.pages[0].layout = def.pages[0].layout || [];
      def.pages[0].layout.push(layoutItem);
    }

    // Update dashboard
    await this.request(
      `/lakeview/dashboards/${dashboardId}`,
      {
        method: "PATCH",
        body: JSON.stringify({
          serialized_dashboard: JSON.stringify(def),
        }),
      },
      "2.0",
    );

    return {
      dashboard_id: dashboardId,
      url: `${this.host}/sql/dashboardsv3/${dashboardId}`,
    };
  }

  async updateDashboardSql(
    dashboardId: string,
    datasetName: string,
    newSql: string,
  ): Promise<void> {
    const existing = await this.request<DashboardInfo>(
      `/lakeview/dashboards/${dashboardId}`,
      {},
      "2.0",
    );

    if (!existing.serialized_dashboard) {
      throw new Error("Dashboard has no content to update.");
    }

    const def: DashboardDefinition = JSON.parse(existing.serialized_dashboard);

    // Find and update dataset
    let found = false;
    for (const dataset of def.datasets) {
      if (dataset.name === datasetName || dataset.displayName === datasetName) {
        dataset.queryLines = newSql.split("\n").map((line) => line + "\n");
        delete dataset.query;
        found = true;
        break;
      }
    }

    if (!found) {
      const available = def.datasets.map((d) => d.name).join(", ");
      throw new Error(
        `Dataset '${datasetName}' not found. Available: ${available}`,
      );
    }

    await this.request(
      `/lakeview/dashboards/${dashboardId}`,
      {
        method: "PATCH",
        body: JSON.stringify({
          serialized_dashboard: JSON.stringify(def),
        }),
      },
      "2.0",
    );
  }

  async publishDashboard(dashboardId: string): Promise<{ url: string }> {
    await this.request(
      `/lakeview/dashboards/${dashboardId}/published`,
      {
        method: "POST",
        body: JSON.stringify({
          warehouse_id: this.warehouseId,
          embed_credentials: true,
        }),
      },
      "2.0",
    );

    return {
      url: `${this.host}/sql/dashboardsv3/${dashboardId}`,
    };
  }

  async deleteDashboard(dashboardId: string): Promise<void> {
    await this.request(
      `/lakeview/dashboards/${dashboardId}`,
      { method: "DELETE" },
      "2.0",
    );
  }

  // ============ Dashboard Helper Methods ============

  private buildDataset(name: string, sql: string): DashboardDataset {
    const queryLines = sql.split("\n").map((line) => line + "\n");
    return {
      name,
      displayName: name,
      queryLines,
    };
  }

  private buildWidget(
    name: string,
    datasetName: string,
    chartType: ChartType,
    xColumn: string,
    yColumns: string[],
    title?: string,
  ): DashboardWidget {
    const displayTitle = title || name;

    // Build spec based on chart type
    // Version 2: counter, table, pie (single-value or categorical)
    // Version 3: bar, line, area, scatter (axis-based)
    let spec: DashboardWidget["spec"];

    if (chartType === "table") {
      spec = {
        version: 2,
        widgetType: "table",
        encodings: {
          columns: [
            { fieldName: xColumn, displayName: xColumn },
            ...yColumns.map((col) => ({ fieldName: col, displayName: col })),
          ],
        },
        frame: { title: displayTitle, showTitle: true },
      };
    } else if (chartType === "counter") {
      spec = {
        version: 2,
        widgetType: "counter",
        encodings: {
          value: { fieldName: yColumns[0] || xColumn },
        },
        frame: { title: displayTitle, showTitle: true },
      };
    } else if (chartType === "pie") {
      spec = {
        version: 2,
        widgetType: "pie",
        encodings: {
          color: { fieldName: xColumn, scale: { type: "categorical" } },
          size: { fieldName: yColumns[0] || xColumn },
        },
        frame: { title: displayTitle, showTitle: true },
      };
    } else {
      // bar, line, area, scatter
      const yEncoding =
        yColumns.length > 1
          ? {
              scale: { type: "quantitative" },
              fields: yColumns.map((col) => ({ fieldName: col })),
            }
          : { fieldName: yColumns[0], scale: { type: "quantitative" } };

      spec = {
        version: 3,
        widgetType: chartType,
        encodings: {
          x: { fieldName: xColumn, scale: { type: "categorical" } },
          y: yEncoding,
        },
        frame: { title: displayTitle, showTitle: true },
      };
    }

    // Build fields for query
    const fields = [
      { name: xColumn, expression: `\`${xColumn}\`` },
      ...yColumns.map((col) => ({ name: col, expression: `\`${col}\`` })),
    ];

    return {
      name,
      queries: [
        {
          name: "main_query",
          query: {
            datasetName,
            fields,
            disaggregated: false,
          },
        },
      ],
      spec,
    };
  }

  private buildLayoutItem(
    widget: DashboardWidget,
    position: { x: number; y: number; width: number; height: number },
  ): DashboardLayoutItem {
    return { widget, position };
  }

  private buildPage(
    name: string,
    layoutItems: DashboardLayoutItem[],
  ): DashboardPage {
    return {
      name,
      displayName: name,
      layout: layoutItems,
      pageType: "PAGE_TYPE_CANVAS",
    };
  }
}
