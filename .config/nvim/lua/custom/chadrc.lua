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

--  TODO:
-- go to test file
-- elixir test mappings
-- better session management
-- theme fixes: vim / highlights are green, invert tab colors, git added should be green not blue, which-key bg, mode in status line simpler, line lighter, the selected line hl
