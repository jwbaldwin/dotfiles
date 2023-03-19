local present, catppuccin = pcall(require, "catppuccin")

if not present then
  return
end

local options = {
  transparent_background = true,
  term_colors = true,
  compile = {
    enabled = false,
    path = vim.fn.stdpath("cache") .. "/catppuccin",
  },
  dim_inactive = {
    enabled = false,
    shade = "dark",
    percentage = 0.15,
  },
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
    loops = { "italic" },
    functions = {},
    keywords = { "italic" },
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = { "italic" },
    operators = {},
  },
  integrations = {
    leap = true,
    gitsigns = true,
    cmp = true,
    notify = true,
    nvimtree = true,
    treesitter = true,
    symbols_outline = true,
    telescope = true,
    which_key = true
    -- For various plugins integrations see https://github.com/catppuccin/nvim#integrations
  },
  color_overrides = {},
  highlight_overrides = {},
}
vim.g.catppuccin_flavour = "mocha"

catppuccin.setup(options)

-- theme
-- vim.cmd [[colorscheme catppuccin]]
