-- n, v, i, t = mode names

local function termcodes(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local M = {}

M.general = {
  i = {
    ["jj"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
    ["kj"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
    ["jk"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
    ["<C-h>"] = { function() vim.lsp.buf.signature_help() end, "signature help" }
  },
  n = {
    -- dashboard
    ["<leader>;"] = { ":Alpha <CR>", "dashboard" },
    ["<leader>fe"] = { ":e ~/.config/nvim/init.lua | :cd %:p:h <CR>", "edit config" },
    ["<leader>fd"] = { ":e ~/.aliases/ | :cd %:p:h <CR>", "edit dotfiles" },

    -- switch between windows
    ["<leader>wh"] = { ":wincmd h<cr>", "window left" },
    ["<leader>wj"] = { ":wincmd j<cr>", "window down" },
    ["<leader>wk"] = { ":wincmd k<cr>", "window up" },
    ["<leader>wl"] = { ":wincmd l<cr>", "window right" },

    -- packer
    ["<leader>ps"] = { ":PackerSync <CR>", "packer sync" },
    ["<leader>pc"] = { ":PackerCompile <CR>", "packer compie" },

    -- copy and save
    ["<C-y>"] = { "<cmd> w <CR>", "save file" },
    ["<C-a>"] = { "<cmd> %y+ <CR>", "copy all" },

    -- misc
    ["<S-Up>"] = { ":move-2<cr>", "shift line up" },
    ["<S-Down>"] = { ":move+<cr>", "shift line down" },
    ["<C-d>"] = { "<C-d>zz", "move down and center" },
    ["<C-u>"] = { "<C-u>zz", "move up and center" },


    -- list movement
    ["<C-q>"] = { "<cmd> lua require('core.utils').toggle_qf_list()<CR>", "toggle qf list" },
    ["<C-n>"] = { "<cmd> cnext<CR>zz", "next qfix list item" },
    ["<C-p>"] = { "<cmd> cprev<CR>zz", "prev qfix list item" },

    -- A better escape (removes highlights)
    ["<ESC>"] = { "<cmd> noh <CR>", "no highlight" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "save file" },

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using <cmd> :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', opts = { expr = true } },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', opts = { expr = true } },

    -- new buffer
    ["<leader>bn"] = { "<cmd> enew <CR>", "new buffer" },

    -- close buffer + hide terminal buffer
    ["<leader>x"] = {
      function()
        require("core.utils").close_buffer()
      end,
      "close buffer",
    },
  },

  t = { ["<C-x>"] = { termcodes "<C-\\><C-N>", "escape terminal mode" } },

  v = {
    -- copy and paste in visual
    ["<C-c>"] = { "<cmd>'<,'>y<CR>", "copy line" },
    ["<C-a>"] = { "<cmd> %y+ <CR>", "copy all" },
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', opts = { expr = true } },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', opts = { expr = true } },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', opts = { silent = true } },
  },
}

M.tabufline = {


  n = {
    -- cycle through buffers
    ["<TAB>"] = {
      function()
        require("core.utils").tabuflineNext()
      end,
      "goto next buffer",
    },

    ["<S-Tab>"] = {
      function()
        require("core.utils").tabuflinePrev()
      end,
      "goto prev buffer",
    },

    -- pick buffers via numbers
    ["<Bslash>"] = { "<cmd> TbufPick <CR>", "Pick buffer" },
  },
}

M.comment = {
  -- toggle comment in both modes
  n = {
    ["<leader>/"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "toggle comment",
    },
  },

  v = {
    ["<leader>/"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "toggle comment",
    },
  },
}

M.lspconfig = {
  i = {
    ["<C-leader>"] = {
      function()
        vim.lsp.buf.completion()
      end,
      "trigger completion"
    },
  },
  n = {
    ["gD"] = {
      function()
        vim.lsp.buf.declaration()
      end,
      "lsp declaration",
    },

    ["gd"] = { "<cmd> lua vim.lsp.buf.definition()<CR>zz", "lsp definition", },

    ["K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      "lsp hover",
    },

    ["gi"] = {
      function()
        vim.lsp.buf.implementation()
      end,
      "lsp implementation",
    },

    ["<leader>lh"] = {
      function()
        vim.lsp.buf.signature_help()
      end,
      "lsp signature_help",
    },

    ["<leader>ls"] = { "<cmd> Telescope lsp_document_symbols <CR>", "list document symbols" },

    ["<leader>D"] = {
      function()
        vim.lsp.buf.type_definition()
      end,
      "lsp definition type",
    },

    ["<leader>ra"] = {
      function()
        require("nvchad_ui.renamer").open()
      end,
      "lsp rename",
    },

    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "lsp code_action",
    },

    ["gr"] = {
      function()
        vim.lsp.buf.references()
      end,
      "lsp references",
    },

    ["<leader>f"] = {
      function()
        vim.diagnostic.open_float()
      end,
      "floating diagnostic",
    },

    ["[d"] = {
      function()
        vim.diagnostic.goto_prev()
      end,
      "goto prev",
    },

    ["d]"] = {
      function()
        vim.diagnostic.goto_next()
      end,
      "goto_next",
    },

    ["<leader>q"] = {
      function()
        vim.diagnostic.setloclist()
      end,
      "diagnostic setloclist",
    },

    ["<leader>fm"] = {
      function()
        vim.lsp.buf.formatting {}
      end,
      "lsp formatting",
    },

    ["<leader>wa"] = {
      function()
        vim.lsp.buf.add_workspace_folder()
      end,
      "add workspace folder",
    },

    ["<leader>wr"] = {
      function()
        vim.lsp.buf.remove_workspace_folder()
      end,
      "remove workspace folder",
    },

    ["<leader>wf"] = {
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      "list workspace folders",
    },
  },
}

M.nvimtree = {
  n = {
    -- toggle
    ["<leader>e"] = { "<cmd> NvimTreeToggle <CR>", "toggle nvimtree" },
  },
}

M.telescope = {


  n = {
    -- find
    ["<leader>."] = { "<cmd> Telescope enhanced_find_files theme=ivy hidden=true <CR>", "find files" },
    ["<leader>fr"] = { "<cmd> Telescope oldfiles theme=ivy hidden=true<CR>", "find recent" },
    ["<leader>'"] = { "<cmd> Telescope live_grep theme=ivy previewer=false<CR>", "live grep" },
    ["<leader>st"] = { "<cmd> Telescope live_grep <CR>", "live grep" },
    ["<leader>,"] = { "<cmd> Telescope buffers theme=ivy<CR>", "find buffers" },
    ["<leader>pp"] = { "<cmd> Telescope projects theme=ivy<CR>", "projects" },
    ["<leader>ss"] = { ":Telescope persisted<CR>", "search sessions" },
    -- more find
    ["<leader>ff"] = { "<cmd> Telescope find_files <CR>", "find files" },
    ["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "find all" },
    ["<leader>fw"] = { "<cmd> Telescope live_grep <CR>", "live grep" },
    ["<leader>fb"] = { "<cmd> Telescope buffers <CR>", "find buffers" },
    ["<leader>fh"] = { "<cmd> Telescope help_tags <CR>", "help page" },
    ["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "find oldfiles" },
    ["<leader>fk"] = { "<cmd> Telescope keymaps <CR>", "show keys" },
    ["<leader>ft"] = { "<cmd> TodoTelescope<CR>", "Show todo comments" },

    -- pick a hidden term
    ["<leader>pt"] = { "<cmd> Telescope terms <CR>", "pick hidden term" },
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

M.whichkey = {
  n = {
    ["<leader>wK"] = {
      function()
        vim.cmd "WhichKey"
      end,
      "which-key all keymaps",
    },
  },
}

M.blankline = {
  n = {
    ["<leader>cc"] = {
      function()
        local ok, start = require("indent_blankline.utils").get_current_context(
          vim.g.indent_blankline_context_patterns,
          vim.g.indent_blankline_use_treesitter_scope
        )

        if ok then
          vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { start, 0 })
          vim.cmd [[normal! _]]
        end
      end,

      "Jump to current_context",
    },
  },
}

M.tabufline = {
  n = {
    ["<S-h>"] = { "<cmd> bprev <CR>", "goto prev buffer", },
    ["<S-l>"] = { "<cmd> bnext <CR>", "goto next buffer", },
    ["<leader>bk"] = {
      function()
        require("core.utils").close_buffer()
      end,
      "close buffers",
    },
    ["<leader>bb"] = { "<cmd> TbufPick <CR>", "pick buffer" },
    ["<leader>bp"] = { "<C-6>", "prev" },
  },
}

M.harpoon = {
  n = {
    ["<C-h>"] = { "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", "toggle harpoon menu" },
    ["<C-j>"] = { "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", "harpoon 1" },
    ["<C-k>"] = { "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", "harpoon 2" },
    ["<C-l>"] = { "<cmd>lua require('harpoon.ui').nav_file(3)<cr>", "harpoon 3" },
    ["<C-_>"] = { "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", "harpoon 4" },
    ["<C-f>"] = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "harpoon: add file" },
  },
}

M.gitsigns = {
  n = {
    ["<leader>gm"] = { "<cmd> Telescope git_commits theme=ivy<CR>", "git commits" },
    ["<leader>gs"] = { "<cmd> Telescope git_status <CR>", "git status" },
    ["<leader>gb"] = { "<cmd> Gitsigns blame_line<CR>", "git blame" },
    ["<leader>gB"] = { "<cmd> Gitsigns toggle_current_line_blame<CR>", "git blame" },
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