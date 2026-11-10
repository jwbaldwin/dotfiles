import { Plugin } from "@opencode/plugin"

const workOnlyMcps = ["zapier-mcp", "sherlock"]
const personalOnlyMcps = ["planetscale"]

export default Plugin.define({
  id: "work-mcps",
  async setup(ctx) {
    const disabledMcps = process.env.WORK === "true" ? personalOnlyMcps : workOnlyMcps

    await ctx.mcp.transform((editor) => {
      for (const name of disabledMcps) {
        editor.update(name, (server) => {
          server.disabled = true
        })
      }
    })
  },
})
