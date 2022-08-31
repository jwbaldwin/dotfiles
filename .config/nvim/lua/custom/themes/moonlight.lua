local M = {}

M.base_30 = {
  white = "#dbe1f8",
  darker_black = "#1e2030", -- telescope results and preview bg
  black = "#222436", --  nvim bg, telescope results bg
  black2 = "#2f334d", -- telescope search bg
  one_bg = "#191a2a", -- real bg of moonlight
  one_bg2 = "#1e2030",
  one_bg3 = "#222436",
  grey = "#444a73",
  grey_fg = "#7a88cf",
  grey_fg2 = "#565C81",
  light_grey = "#a9b8e8",
  red = "#ff757f",
  baby_pink = "#ff98a4",
  pink = "#f3c1ff",
  line = "#2f334d", -- for lines like vertsplit
  green = "#c3e88d",
  vibrant_green = "#7eca9c",
  nord_blue = "#82aaff",
  blue = "#82aaff",
  yellow = "#ffc777",
  sun = "#ff5370",
  purple = "#f989d3",
  dark_purple = "#c099ff",
  teal = "#77e0c6",
  orange = "#ff966c",
  cyan = "#b4f9f8",
  statusline_bg = "#1e2030",
  lightbg = "#2a2d46",
  pmenu_bg = "#2f334d",
  folder_bg = "#82aaff",
}

M.base_16 = {
  base00 = "#222436",
  base01 = "#2f334d",
  base02 = "#444a73",
  base03 = "#828bb8",
  base04 = "#a9b8e8",
  base05 = "#ced6f5",
  base06 = "#c8d3f5",
  base07 = "#c8ccd4",
  base08 = "#ffc777",
  base09 = "#ff966c",
  base0A = "#c3e88d",
  base0B = "#c3e88d",
  base0C = "#dbe1f8",
  base0D = "#82aaff",
  base0E = "#c099ff",
  base0F = "#dbe1f8",
}

vim.opt.bg = "dark"

M = require("base46").override_theme(M, "moonlight")

return M
