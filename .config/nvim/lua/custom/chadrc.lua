local M = {}

M.ui = {
  theme_toggle = { "tokyonight", "palenight" },
  theme = "moonlight",
  hl_override = require("custom.highlights").override,
  hl_add = require("custom.highlights").add
}

local pluginConfs = require "custom.p.configs"

M.plugins = {
  user = require "custom.p.plugins",
  override = {
    ["nvim-treesitter/nvim-treesitter"] = pluginConfs.treesitter,
    ["kyazdani42/nvim-tree.lua"] = pluginConfs.nvimtree,
    ["NvChad/ui"] = pluginConfs.ui,
    ["hrsh7th/nvim-cmp"] = pluginConfs.cmp,
  },
  remove = {
    "NvChad/nvterm",
  },
}

M.mappings = require "custom.mappings"

return M
