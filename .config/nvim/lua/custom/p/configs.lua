local M = {}

M.treesitter = {
   ensure_installed = {
      "lua",
      "html",
      "css",
      "elixir"
   },
}

M.nvimtree = {
   git = {
      enable = true,
   },
}
M.ui = {
  statusline = {
     separator_style = "round",
  },
}


return M
