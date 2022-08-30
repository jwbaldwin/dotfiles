local M = {}

M.disabled = {
  n = {
    ["<C-c>"] = "",
    ["<leader>cm"] = "",
    ["<leader>gt"] = "",
    ["S"] = "",
    ["<leader>n"] = ""
  },
}

M.base = {
  n = {
    -- dashboard
    ["<leader>;"] = { ":Alpha <CR>", "dashboard" },
    ["<leader>fe"] = { ":e ~/.config/nvim/lua/custom/chadrc.lua | :cd %:p:h <CR>", "edit config" },
    ["<leader>f."] = { ":e ~/.aliases/ | :cd %:p:h <CR>", "edit dotfiles" },

    -- window nav
    ["<leader>wh"] = { ":wincmd h<cr>", "window left" },
    ["<leader>wj"] = { ":wincmd j<cr>", "window down" },
    ["<leader>wk"] = { ":wincmd k<cr>", "window up" },
    ["<leader>wl"] = { ":wincmd l<cr>", "window right" },

    -- packer
    ["<leader>ps"] = { ":PackerSync <CR>", "packer sync" },
    ["<leader>pc"] = { ":PackerCompile <CR>", "packer compie" },

    -- copy and save
    ["<C-y>"] = { "<cmd> w <CR>", "save file" },
    ["<C-c>"] = { "<cmd> y <CR>", "copy line" },
    ["<C-a>"] = { "<cmd> %y+ <CR>", "copy all" },

    -- misc
    ["S-Up"] = { ":move-2<cr>", "shift line up" },
    ["S-Down"] = { ":move+<cr>", "shift line down" },
  },
  i = {
    ["kk"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
    ["jj"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
    ["kj"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
    ["jk"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
  },
  v = {
    -- copy and paste in visual
    ["<C-c>"] = { "<cmd>'<,'>y<CR>", "copy line" },
    ["<C-a>"] = { "<cmd> %y+ <CR>", "copy all" },
  }
}

M.nvimtree = {
  n = {
    ["<leader>e"] = { "<cmd> NvimTreeToggle <CR>", "toggle nvimtree" },
  },
}

M.telescope = {
  n = {
    ["<leader>."] = { "<cmd> Telescope find_files theme=ivy hidden=true <CR>", "find files" },
    ["<leader>fr"] = { "<cmd> Telescope oldfiles theme=ivy hidden=true<CR>", "find recent" },
    ["<leader>'"] = { "<cmd> Telescope live_grep theme=ivy previewer=false<CR>", "live grep" },
    ["<leader>st"] = { "<cmd> Telescope live_grep <CR>", "live grep" },
    ["<leader>,"] = { "<cmd> Telescope buffers theme=ivy<CR>", "find buffers" },
    ["<leader>pp"] = { "<cmd> Telescope projects theme=ivy<CR>", "projects" },
    ["<leader>ss"] = { ":Telescope session-lens search_session<CR>", "search sessions" },
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
      end,
      "pick buffer",
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
    ["<C-h>"] = { "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", "toggle harpoon menu" },
    ["<C-e>"] = { "<cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>", "toggle harpoon cmd ui" },
    ["<C-j>"] = { "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", "harpoon 1" },
    ["<C-k>"] = { "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", "harpoon 2" },
    ["<C-l>"] = { "<cmd>lua require('harpoon.ui').nav_file(3)<cr>", "harpoon 3" },
    ["<C-;>"] = { "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", "harpoon 4" },
    ["<C-f>"] = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "harpoon: add file" },
  },
}

M.gitsigns = {
  n = {
    ["<leader>gm"] = { "<cmd> Telescope git_commits theme=ivy<CR>", "git commits" },
    ["<leader>gs"] = { "<cmd> Telescope git_status <CR>", "git status" },
    ["<leader>gb"] = { "<cmd> Gitsigns toggle_current_line_blame<CR>", "git blame" },
    ["<leader>gr"] = { "<cmd> Gitsigns reset_hunk <CR>", "git reset hunk" },
    ["<leader>gR"] = { "<cmd> Gitsigns reset_buffer <CR>", "git reset buffer" },
    ["<leader>gp"] = { "<cmd> Gitsigns preview_hunk <CR>", "preview hunk" },
  },
}

M.neorg = {
  n = {
    ["<leader>na"] = { "<cmd> Neorg gtd capture <CR>", "Neorg add todo" },
    ["<leader>nv"] = { "<cmd> Neorg gtd views <CR>", "Neorg add todo" },
    ["<leader>ne"] = { "<cmd> Neorg gtd edit <CR>", "Neorg edit todo" }
  }
}

M.projectionist = {
  n = {
    ["<leader>ma"] = { "<cmd> A <CR>", "Go to alternate file" }
  }
}

M.test = {
  n = {
    ["<leader>mm"] = { "<cmd> TestFile <CR>", "Test file" },
    ["<leader>mf"] = { "<cmd> TestFile <CR>", "Test file" },
    ["<leader>ms"] = { "<cmd> TestNearest <CR>", "Test single" },
    ["<leader>ml"] = { "<cmd> TestLast <CR>", "Test last run" },
    ["<leader>mp"] = { "<cmd> TestSuite <CR>", "Run tests for whole project" },
    ["<leader>mv"] = { "<cmd> TestVisit <CR>", "Go back to last-run test file" },
  }
}

return M
