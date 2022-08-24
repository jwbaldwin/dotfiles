-- Just an example, supposed to be placed in /lua/custom/
local M = {}

-- make sure you maintain the structure of `core/default_config.lua` here,
-- example of changing theme:
M.ui = {
  theme = "tokyonight",
}

local pluginConfs = require("custom.p.configs")

M.plugins = {
  user = require("custom.p"),
  override = {
      ["nvim-treesitter/nvim-treesitter"] = pluginConfs.treesitter,
      ["kyazdani42/nvim-tree.lua"] = pluginConfs.nvimtree,
      ["NvChad/ui"] = pluginConfs.ui,
    },
}

M.mappings = require("custom.mappings")

return M

--  TODO: 
-- add projects into telescope
-- fix icons
-- customize dashboard
