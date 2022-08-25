local M = {}

-- lvim.keys.normal_mode["<D-/>"] = "<Plug>(comment_toggle_linewise_visual)"

M.base = {
  n = {
    -- dashboard
    ["<leader>;"] = { ":Alpha <CR>", "dashboard"},

    -- window nav
    ["<leader>wh"] = { ":wincmd h<cr>", "window left"},
    ["<leader>wj"] = { ":wincmd j<cr>", "window down"},
    ["<leader>wk"] = { ":wincmd k<cr>", "window up"},
    ["<leader>wl"] = { ":wincmd l<cr>", "window right"},

    -- packer
    ["<leader>ps"] = { ":PackerSync <CR>", "packer sync"},
    ["<leader>pc"] = { ":PackerCompile <CR>", "packer compie"},

    -- misc
    ["S-Up"] = {":move-2<cr>", "shift line up"},
    ["S-Down"] = {":move+<cr>", "shift line down"}
  },
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
    ["<leader>'"] = { "<cmd> Telescope live_grep <CR>", "live grep" },
    ["<leader>,"] = { "<cmd> Telescope buffers <CR>", "find buffers" },
    ["<leader>pp"] = { "<cmd> Telescope project <CR>", "projects" },
  },
}

M.FTerm = {
  t = {
    ["<C-t>"] = {
      function()
        require("FTerm").toggle()
      end,
      "toggle floating term",
    },
  },
  n = {
    ["<C-t>"] = {
      function()
        require("FTerm").toggle()
      end,
      "toggle floating term",
    },
  },
}

M.tabufline = {
  n = {
    ["<S-h>"] = {
      function()
        require("core.utils").tabuflinePrev()
      end,
      "goto prev buffer",
    },
    ["<S-l>"] = {
      function()
        require("core.utils").tabuflineNext()
      end,
      "goto next buffer",
    },
    ["<leader>bk"] = {
        function()
          require("core.utils").close_buffer()
        end,
        "close buffers",
    },
    ["<leader>bb"] = { "<cmd> TbufPick <CR>", "pick buffer" },
    ["<leader>bp"] = {
      function()
        require("core.utils").tabuflinePrev()
      end, "pick buffer"
    },
  },
}

M.comment = {
  n = {
    ["<M-/>"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "toggle comment",
    },
  },

  v = {
    ["<M-/>"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "toggle comment",
    },
  },
}

M.lspconfig = {
  n = {
    ["<leader>fm"] = {
      function()
        vim.lsp.buf.format {}
      end,
      "lsp formatting",
    },
  },
}

M.harpoon = {
  n = {
    ["<C-h>"] = {"<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", "toggle harpoon menu"},
    ["<C-e>"] = {"<cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", "toggle harpoon cmd ui"},
    ["<C-j>"] = {"<cmd>lua require('harpoon.ui').nav_file(1)<cr>", "harpoon 1"},
    ["<C-k>"] = {"<cmd>lua require('harpoon.ui').nav_file(2)<cr>", "harpoon 2"},
    ["<C-l>"] = {"<cmd>lua require('harpoon.ui').nav_file(3)<cr>", "harpoon 3"},
    ["<C-;>"] = {"<cmd>lua require('harpoon.ui').nav_file(4)<cr>", "harpoon 4"},
    ["<C-f>"] = {"<cmd>lua require('harpoon.mark').add_file()<cr>", "harpoon: add file"},
  }
}

return M
