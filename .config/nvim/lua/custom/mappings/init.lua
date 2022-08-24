local M = {}

M.base = {
  i = {
     ["kk"] = { "<ESC>", "escape insert mode" , opts = { nowait = true }},
     ["jj"] = { "<ESC>", "escape insert mode" , opts = { nowait = true }},
     ["kj"] = { "<ESC>", "escape insert mode" , opts = { nowait = true }},
     ["jk"] = { "<ESC>", "escape insert mode" , opts = { nowait = true }},
  },
}

M.nvimtree = {
  n = {
    ["<leader>e"] = { "<cmd> NvimTreeToggle <CR>", "toggle nvimtree" },
  },

}

M.telescope = {
  n = {
    ["<leader>."] = { "<cmd> Telescope find_files <CR>", "find files" },
    ["<leader>/"] = { "<cmd> Telescope live_grep <CR>", "live grep" },
    ["<leader>,"] = { "<cmd> Telescope buffers <CR>", "find buffers" },
  },
}

M.nvterm = {
  t = {
    ["<C-t>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "toggle floating term",
    },
  },
  n = {
    ["<C-t>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "toggle floating term",
    },
  },
}

return M
