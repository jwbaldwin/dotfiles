import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function workMcps(pi: ExtensionAPI) {
  if (process.env.WORK !== "true") {
    pi.registerMcpServer("planetscale", { url: "https://mcp.pscale.dev/mcp/planetscale" });
    return;
  }

  pi.registerMcpServer("zapier-mcp", { url: "https://mcp.zapier.com/api/v1/connect" });
  pi.registerMcpServer("sherlock", {
    url: "https://sherlockbackend.global-us-east-1.int.zapier.com/v1/mcp",
  });
}
