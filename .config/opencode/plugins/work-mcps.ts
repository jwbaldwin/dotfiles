import { Plugin } from "@opencode/plugin"

export default Plugin.define({
  id: "work-mcps",
  async setup(ctx) {
    if (process.env.WORK === "true") return

    await ctx.mcp.transform((editor) => {
      for (const name of ["zapier-mcp", "sherlock"]) {
        editor.update(name, (server) => {
          server.disabled = true
        })
      }
    })
  },
})
