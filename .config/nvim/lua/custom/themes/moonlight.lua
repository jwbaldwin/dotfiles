local M = {}

M.base_30 = {
  white = "#c8d3f5",
  darker_black = "#171827",
  black = "#171827", --  nvim bg
  black2 = "#212337",
  one_bg = "#2a2d46", -- real bg of onedark
  one_bg2 = "#2f324e",
  one_bg3 = "#343756",
  grey = "#444a73",
  grey_fg = "#7a88cf",
  grey_fg2 = "#b4c2f0",
  light_grey = "#a9b8e8",
  red = "#ff757f",
  baby_pink = "#ff98a4",
  pink = "#f3c1ff",
  line = "#31353d", -- for lines like vertsplit
  green = "#c3e88d",
  vibrant_green = "#7eca9c",
  nord_blue = "#82aaff",
  blue = "#4976eb",
  yellow = "#ffc777",
  sun = "#ff0000",
  purple = "#f989d3",
  dark_purple = "#c099ff",
  teal = "#77e0c6",
  orange = "#ff995e",
  cyan = "#b4f9f8",
  statusline_bg = "#1e2030",
  lightbg = "#2a2d46",
  pmenu_bg = "#82aaff",
  folder_bg = "#82aaff",
}

M.base_16 = {
  base00 = "#212337",
  base01 = "#2f324e",
  base02 = "#383e5c",
  base03 = "#343756",
  base04 = "#444a73",
  base05 = "#c8ccd4",
  base06 = "#b6bdca",
  base07 = "#c8ccd4",
  base08 = "#ffc777",
  base09 = "#00ff00",
  base0A = "#00ff00",
  base0B = "#c3e88d",
  base0C = "#b4f9f8",
  base0D = "#82aaff",
  base0E = "#c099ff",
  base0F = "#c8d3f5",
}

vim.opt.bg = "dark"

M = require("base46").override_theme(M, "moonlight")

return M
