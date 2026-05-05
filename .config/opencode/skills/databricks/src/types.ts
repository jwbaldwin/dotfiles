// Unity Catalog Types

export interface CatalogInfo {
  name: string;
  comment?: string;
  catalog_type?: string;
  owner?: string;
  created_at?: number;
}

export interface SchemaInfo {
  name: string;
  catalog_name: string;
  full_name: string;
  comment?: string;
  owner?: string;
}

export interface ColumnInfo {
  name: string;
  type_text: string;
  type_name: string;
  nullable: boolean;
  comment?: string;
  partition_index?: number;
}

export interface TableInfo {
  name: string;
  catalog_name: string;
  schema_name: string;
  full_name: string;
  table_type: string;
  comment?: string;
  columns?: ColumnInfo[];
  owner?: string;
  created_at?: number;
}

// SQL Execution Types

export interface StatementResponse {
  statement_id: string;
  status: {
    state:
      | "PENDING"
      | "RUNNING"
      | "SUCCEEDED"
      | "FAILED"
      | "CANCELED"
      | "CLOSED";
    error?: {
      error_code: string;
      message: string;
    };
  };
  manifest?: {
    format: string;
    schema: {
      columns: Array<{
        name: string;
        type_text: string;
        type_name: string;
      }>;
    };
    total_row_count?: number;
  };
  result?: {
    data_array?: Array<Array<string | number | boolean | null>>;
    row_count?: number;
  };
}

export interface QueryResult {
  status: "success" | "failed" | "error";
  columns?: string[];
  data?: Array<Record<string, unknown>>;
  rowCount?: number;
  error?: string;
  details?: string;
}

// SQL Warehouse Types

export interface WarehouseInfo {
  id: string;
  name: string;
  state: string;
  cluster_size?: string;
  auto_stop_mins?: number;
  creator_name?: string;
  num_clusters?: number;
  warehouse_type?: string;
}

export interface WarehouseListResponse {
  warehouses?: WarehouseInfo[];
}

// Async Query Types

export interface AsyncQueryResult {
  statement_id: string;
  state: string;
  error?: string;
}

// User Info Types

export interface CurrentUser {
  id: string;
  userName: string;
  displayName: string;
  emails?: Array<{ value: string; primary?: boolean }>;
  active: boolean;
}

// Dashboard Types

export type ChartType =
  | "bar"
  | "line"
  | "area"
  | "scatter"
  | "pie"
  | "table"
  | "counter";

export interface DashboardInfo {
  dashboard_id: string;
  display_name: string;
  parent_path?: string;
  warehouse_id?: string;
  lifecycle_state?: string;
  serialized_dashboard?: string;
  create_time?: string;
  update_time?: string;
}

export interface DashboardListResponse {
  dashboards?: DashboardInfo[];
  next_page_token?: string;
}

export interface DashboardDataset {
  name: string;
  displayName?: string;
  query?: string;
  queryLines?: string[];
}

export interface DashboardWidget {
  name: string;
  queries?: Array<{
    name: string;
    query: {
      datasetName: string;
      fields?: Array<{ name: string; expression: string }>;
      disaggregated?: boolean;
    };
  }>;
  spec?: {
    version: number;
    widgetType: string;
    encodings?: Record<string, unknown>;
    frame?: {
      title?: string;
      showTitle?: boolean;
    };
  };
}

export interface DashboardLayoutItem {
  widget: DashboardWidget;
  position: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

export interface DashboardPage {
  name: string;
  displayName?: string;
  layout?: DashboardLayoutItem[];
  pageType?: string;
}

export interface DashboardDefinition {
  datasets: DashboardDataset[];
  pages: DashboardPage[];
}

export interface ParsedDashboard {
  dashboard_id: string;
  name: string;
  parent_path?: string;
  lifecycle_state?: string;
  url: string;
  datasets: Array<{
    name: string;
    display_name?: string;
    query?: string;
  }>;
  charts: Array<{
    name: string;
    title?: string;
    chart_type?: string;
    page?: string;
    dataset?: string;
  }>;
}
