import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function workMcps(pi: ExtensionAPI) {
  if (process.env.WORK !== "true") return;

  const zapierMcpUrl = process.env.ZAPIER_MCP_URL;
  if (zapierMcpUrl) pi.registerMcpServer("zapier-mcp", { url: zapierMcpUrl });
  pi.registerMcpServer("sherlock", {
    url: "https://sherlockbackend.global-us-east-1.int.zapier.com/v1/mcp",
  });
}
