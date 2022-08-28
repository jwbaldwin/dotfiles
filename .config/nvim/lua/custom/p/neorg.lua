local neorg = require("neorg")

neorg.setup {
  load = {
    ["core.defaults"] = {},
    ["core.gtd.base"] = {
      config = {
        workspace = "project"
      }
    },
    ["core.norg.concealer"] = {
    },
    ["core.norg.completion"] = {
      config = {
        engine = "nvim-cmp"
      }
    },
    ["core.norg.dirman"] = {
      config = {
        workspaces = {
          project = "~/neorg/project",
        }
      }
    }
  }
}
