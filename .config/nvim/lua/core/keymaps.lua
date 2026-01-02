-- n, v, i, t = mode names
local utils = require("core.utils")
local test_runner = require("core.test_runner")
local yank = utils["yank"]

local function termcodes(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local M = {}

M.general = {
	i = {
		["kj"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
		["jk"] = { "<ESC>", "escape insert mode", opts = { nowait = true } },
		["<C-h>"] = {
			function()
				vim.lsp.buf.signature_help()
			end,
			"signature help",
		},
	},
	n = {
		-- dashboard
		-- ["<leader>;"] = { ":Alpha <CR>", "dashboard" },
		["<leader>fe"] = { ":e ~/.config/nvim/init.lua | :cd %:p:h <CR>", "edit config" },
		["<leader>fd"] = { ":e ~/.aliases/ | :cd %:p:h | :e .<CR>", "edit dotfiles" },
		-- reload neovim config
		["<leader>rc"] = {
			":lua package.loaded['oscura'] = nil; require('oscura').setup(); vim.cmd('colorscheme oscura')",
			"reload neovim config",
		},

		-- switch between windows
		["<leader>h"] = { ":wincmd h<cr>", "window left" },
		["<leader>j"] = { ":wincmd j<cr>", "window down" },
		["<leader>k"] = { ":wincmd k<cr>", "window up" },
		["<leader>l"] = { ":wincmd l<cr>", "window right" },

		-- copy and save
		["<C-y>"] = { "<cmd> w <CR>", "save file" },
		["<C-a>"] = { "<cmd> %y+ <CR>", "copy all" },

		-- copy relative filepath
		["<leader>yf"] = {
			function()
				yank(vim.fn.expand("%:s"))
			end,
			"copy current filepath to clipboard",
		},
		["<leader>yF"] = { "<cmd>:let @+ = expand('%:s') <CR>", "copy absolute filepath to clipboard" },
		["<leader>yg"] = { "<cmd>GBrowse!<CR>", "copy gitlab source" },

		-- copy elixr module name (local and absolute)
		["<leader>yM"] = {
			function()
				yank(utils.current_local_module())
			end,
			"copy the elixir module name",
		},
		["<leader>ym"] = {
			function()
				yank(utils.current_absolute_module())
			end,
			"copy the full elixir module name",
		},

		-- misc movement
		["<S-Up>"] = { ":move-2<cr>", "shift line up" },
		["<S-Down>"] = { ":move+<cr>", "shift line down" },
		["<C-d>"] = { "<C-d>", "move down and center" },
		["<C-u>"] = { "<C-u>", "move up and center" },

		-- list movement
		["<C-q>"] = { "<cmd> lua require('core.utils').toggle_qf_list()<CR>", "toggle qf list" },
		["<C-n>"] = { "<cmd> cnext<CR>zz", "next qfix list item", { noremap = true, silent = true } },
		["<C-p>"] = { "<cmd> cprev<CR>zz", "prev qfix list item", { noremap = true, silent = true } },

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

		-- cycle buffers
		["<leader>bp"] = { "<cmd> :bprev<CR>", "previous buffer" },
		["<leader>bn"] = { "<cmd> :bnext<CR>", "next buffer" },
		["<leader>bl"] = { "<C-6>", "toggle between last buffer" },

		-- create buffer
		["<leader>bc"] = { "<cmd> enew <CR>", "new buffer" },

		-- close buffer + hide terminal buffer
		["<leader>x"] = {
			function()
				utils.close_buffer()
			end,
			"close buffer",
		},
	},
	t = { ["<C-x>"] = { termcodes("<C-\\><C-N>"), "escape terminal mode" } },
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

if os.getenv("USER") == "jbaldwin" and os.getenv("WORK") == "true" then
	M.copilot = {
		i = {
			["<C-y>"] = {
				'copilot#Accept("")',
				"Accept copilot with Control-y",
				opts = { expr = true, replace_keycodes = false },
			},
			["<C-]>"] = { "<Plug>(copilot-next)", "Next copilot suggestion" },
			["<C-[>"] = { "<Plug>(copilot-previous)", "Previous copilot suggestion" },
			["<C-w>"] = { "<Plug>(copilot-accept-word)", "Accept copilot word" },
			["<C-l>"] = { "<Plug>(copilot-accept-line)", "Accept copilot line" },
			["<C-c>"] = { "<Plug>(copilot-dismiss)", "Dismiss copilot" },
		},
	}
end

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
	n = {
		["gD"] = {
			function()
				vim.lsp.buf.declaration()
			end,
			"lsp declaration",
		},
		["gd"] = { "<cmd> lua vim.lsp.buf.definition()<CR>zz", "lsp definition" },
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
		["<leader>D"] = {
			function()
				vim.lsp.buf.type_definition()
			end,
			"lsp definition type",
		},
		["<leader>rn"] = {
			function()
				vim.lsp.buf.rename()
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
				vim.lsp.buf.formatting({})
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

M.oil = {
	n = {
		["<leader>o"] = { "<cmd>lua require('oil').toggle_float()<CR>", "toggle oil" },
	},
}

M.telescope = {
	n = {
		-- find
		-- ["<leader>."] = { "<cmd> Telescope smart_open theme=ivy hidden=true <CR>", "find files" },
		-- ["<leader>,"] = { "<cmd> Telescope buffers theme=ivy<CR>", "find buffers" },
		-- ["<leader>'"] = { "<cmd> lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", "live grep" },
		["<leader>sw"] = {
			function()
				local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
				live_grep_args_shortcuts.grep_word_under_cursor()
			end,
			"search the word under cursor",
		},
		["<leader>sm"] = {
			function()
				local module = utils.current_local_module()
				require("snacks").picker.grep({ search = module })
			end,
			"search with current module name",
		},
		["<leader>sd"] = {
			function()
				local module = utils.current_absolute_module()
				require("snacks").picker.grep({ search = module .. " do" })
			end,
			"search with current module name and do at the end to find the definition",
		},
		["<leader>sM"] = {
			function()
				local module = utils.current_absolute_module()
				require("snacks").picker.grep({ search = module })
			end,
			"search with current absolute module name",
		},
		["<leader>sp"] = { "<cmd> Telescope projects theme=ivy<CR>", "projects" },

		-- more find
		-- ["<leader>ff"] = { "<cmd> Telescope enhanced_find_files theme=ivy hidden=true <CR>", "find files" },
		["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "find all" },
		["<leader>f0"] = { "<cmd> Telescope live_grep <CR>", "live grep old" },
		["<leader>fw"] = { "<cmd> Telescope live_grep theme=ivy previewer=false<CR>", "live grep" },
		["<leader>fb"] = { "<cmd> Telescope buffers <CR>", "find buffers" },
		["<leader>fh"] = { "<cmd> Telescope help_tags <CR>", "help page" },
		["<leader>fr"] = { "<cmd> Telescope oldfiles theme=ivy hidden=true<CR>", "find recent" },
		["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "find oldfiles" },
		["<leader>fk"] = { "<cmd> Telescope keymaps <CR>", "show keys" },
		-- pick a hidden term
		["<leader>pt"] = { "<cmd> Telescope terms <CR>", "pick hidden term" },
		-- Folke Todo Comment
		["<leader>ct"] = { "<cmd> TodoTelescope<CR>", "Show todo comments in telescope" },
		["<leader>cl"] = { "<cmd> TodoLocList<CR>", "Show todo comments in a loc list" },
		["<leader>cq"] = { "<cmd> TodoQuickFix<CR>", "Show todo comments in a quickfix list" },
	},
}

M.spectre = {
	n = {
		["<leader>sr"] = { "<cmd> lua require('spectre').open()<CR>", "Spectre replace" },
	},
}

M.FTerm = {
	t = {
		["<C-\\>"] = { "<cmd>ToggleTerm direction='float'<CR>", "toggle floating term" },
		["<C-t>"] = { "<cmd>ToggleTerm direction='vertical'<CR>", "toggle side pane term" },
	},
	n = {
		["<C-\\>"] = { "<cmd>ToggleTerm direction='float'<CR>", "toggle floating term" },
		["<C-t>"] = { "<cmd>ToggleTerm direction='vertical'<CR>", "toggle side pane term" },
	},
}

M.whichkey = {
	n = {
		["<leader>wK"] = {
			function()
				vim.cmd("WhichKey")
			end,
			"which-key all keymaps",
		},
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
		["<leader>gp"] = { "<cmd> Gitsigns preview_hunk_inline<CR>", "preview git change inline" },
		["<leader>gP"] = { "<cmd> Gitsigns preview_hunk<CR>", "preview git change" },
		["<leader>gb"] = { "<cmd> Gitsigns blame_line<CR>", "git blame" },
		["<leader>gr"] = { "<cmd> Gitsigns reset_hunk <CR>", "git reset hunk" },
		["<leader>gR"] = { "<cmd> Gitsigns reset_buffer <CR>", "git reset buffer" },
		["]c"] = {
			function()
				if vim.wo.diff then
					return "]c"
				end
				vim.schedule(function()
					require("gitsigns").next_hunk()
				end)
				return "<Ignore>"
			end,
			"next hunk",
			opts = { expr = true },
		},
		["[c"] = {
			function()
				if vim.wo.diff then
					return "[c"
				end
				vim.schedule(function()
					require("gitsigns").prev_hunk()
				end)
				return "<Ignore>"
			end,
			"prev hunk",
			opts = { expr = true },
		},
	},
}

M.fugitive = {
	n = {
		["<leader>G"] = { "<cmd>0Git<CR>", "Full buffer git" },
		["<leader>gg"] = { "<cmd>Git<CR>", "Half buffer git" },
		["<leader>gy"] = {
			function()
				utils.browse_default_branch()
			end,
			"copy gitlab link in default branch",
		},
		["<leader>gY"] = { "<cmd>.GBrowse! HEAD:%<CR>", "copy gitlab link at current commit" },
		["<leader>gD"] = { "<cmd>Gvdiffsplit!<CR>", "git diff 3 way split" },
		["<leader>gdl"] = { "<cmd>:diffget //2<CR>", "take change from left (HEAD aka MASTER)" },
		["<leader>gdr"] = { "<cmd>:diffget //3<CR>", "take change from right (BRANCH aka my changes)" },
	},
	v = {
		["<leader>gy"] = { "<cmd>'<,'>GBrowse! HEAD:%<CR>", "copy gitlab link with line number" },
	},
}

M.projectionist = {
	n = {
		["<leader>a"] = { "<cmd> A <CR>", "Go to alternate file" },
	},
}

M.mix = {
	n = {
		["<leader>mc"] = { "<cmd>!mix compile <CR>", "mix compile" },
		["<leader>mf"] = { "<cmd>!mix format <CR>", "mix format" },
	},
}

M.notify = {
	n = {
		-- ["<leader>nd"] = { "<cmd>lua require('notify').dismiss()<CR>", "Dismiss notifications" },
		-- ["<leader>nn"] = { "<cmd>Telescope notify<CR>", "Telescope notifications" },
		-- ["<leader>nl"] = { "<cmd>Notifications<CR>", "List notifications" },
	},
}

M.test = {
	n = {
		["<leader>tp"] = {
			function()
				test_runner.test_suite()
			end,
			"Run tests for whole project",
		},
		["<leader>tv"] = {
			function()
				test_runner.test_visit()
			end,
			"Go back to last-run test file",
		},
		["<leader>tl"] = {
			function()
				test_runner.test_last()
			end,
			"Test last run",
		},
		["<leader>tf"] = {
			function()
				test_runner.test_file()
			end,
			"Test file (filetype-aware)",
		},
		["<leader>tm"] = {
			function()
				test_runner.test_file()
			end,
			"Test module/file (filetype-aware)",
		},
		["<leader>ts"] = {
			function()
				test_runner.test_line()
			end,
			"Test single/nearest (filetype-aware)",
		},
		["<leader>ti"] = {
			function()
				test_runner.test_interactive()
			end,
			"Test interactive/watch mode",
		},
	},
}

return M
