-- Just an example, supposed to be placed in /lua/custom/
local M = {}

M.ui = {
  theme_toggle = { "tokyonight", "catppuccin" },
  theme = "tokyonight",
  hl_override = require("custom.highlights"),
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

--  TODO:
-- format on save
-- go to test file
-- add session keymap
-- go to these files keymap
