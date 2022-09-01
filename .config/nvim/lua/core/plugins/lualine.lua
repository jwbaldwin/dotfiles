local present, lualine = pcall(require, "lualine")
if not present then
  return
end

local separators = require("core.icons").statusline_separators["block"]
local sep_r = separators["left"]
local sep_l = separators["right"]

local options = {
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = sep_l, right = sep_r },
    section_separators = { left = sep_l, right = sep_r },
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { 'filename' },
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}

lualine.setup(options)
