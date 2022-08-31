local M = {}

local highlights = require("custom.highlights")

M.ui = {
  theme_toggle = { "tokyostorm", "moonlight" },
  theme = "moonlight",
  hl_override = highlights[M.ui.theme].override,
  hl_add = highlights[M.ui.theme].add
}

local pluginConfs = require "custom.p.configs"

M.plugins = {
  user = require "custom.p.plugins",
  override = {
    ["nvim-treesitter/nvim-treesitter"] = pluginConfs.treesitter,
    ["kyazdani42/nvim-tree.lua"] = pluginConfs.nvimtree,
    ["NvChad/ui"] = pluginConfs.ui,
    ["hrsh7th/nvim-cmp"] = pluginConfs.cmp,
    ["lewis6991/gitsigns.nvim"] = pluginConfs.gitsigns,
  },
  remove = {
    "NvChad/nvterm",
  },
}

M.mappings = require "custom.mappings"

return M
