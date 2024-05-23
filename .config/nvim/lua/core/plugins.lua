-- Automatically setup lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- plugins here
require("lazy").setup({
	-- base
	{ "folke/lazy.nvim", version = "*" },
	"nvim-lua/plenary.nvim",
	{
		"danielfalk/smart-open.nvim",
		branch = "0.2.x",
		config = function()
			require("telescope").load_extension("smart_open")
		end,
		dependencies = {
			"kkharji/sqlite.lua",
			-- Only required if using match_algorithm fzf
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			-- Optional.  If installed, native fzy will be used when match_algorithm is fzy
			{ "nvim-telescope/telescope-fzy-native.nvim" },
		},
	},
	{
		"kyazdani42/nvim-web-devicons",
		config = function()
			require("core.plugins.configs").devicons()
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		lazy = true,
		init = function()
			require("core.utils").load_mappings("blankline")
		end,
		config = function()
			require("core.plugins.configs").blankline()
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		version = false,
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("core.plugins._treesitter")
		end,
	},
	{ "nvim-treesitter/playground", event = "VeryLazy" },

	-- git stuff
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPre",
		config = function()
			require("core.plugins.configs").gitsigns()
		end,
	},

	-- lsp stuff
	{
		"williamboman/mason.nvim",
		cmd = require("core.utils").mason_cmds,
		config = function()
			require("core.plugins._mason")
		end,
	},

	{
		"neovim/nvim-lspconfig",
		lazy = true,
		config = function()
			require("core.plugins._lspconfig")
		end,
	},
	-- {
	-- 	"elixir-tools/elixir-tools.nvim",
	-- 	version = "*",
	-- 	event = { "BufReadPre", "BufNewFile" },
	-- 	config = function()
	-- 		local elixir = require("elixir")
	-- 		local elixirls = require("elixir.elixirls")
	--
	-- 		elixir.setup({
	-- 			nextls = {
	-- 				enable = true,
	-- 				cmd = "/Users/jwbaldwin/.local/share/nvim/mason/packages/nextls/next_ls_darwin_arm64",
	-- 				init_options = {
	-- 					experimental = {
	-- 						completions = {
	-- 							enable = true,
	-- 						},
	-- 					},
	-- 				},
	-- 			},
	-- 			credo = {},
	-- 			elixirls = {
	-- 				enable = true,
	-- 				settings = elixirls.settings({
	-- 					dialyzerEnabled = false,
	-- 					enableTestLenses = false,
	-- 				}),
	-- 				on_attach = function(client, bufnr)
	-- 					vim.keymap.set("n", "<space>lfp", ":ElixirFromPipe<cr>", { buffer = true, noremap = true })
	-- 					vim.keymap.set("n", "<space>ltp", ":ElixirToPipe<cr>", { buffer = true, noremap = true })
	-- 					vim.keymap.set("v", "<space>lem", ":ElixirExpandMacro<cr>", { buffer = true, noremap = true })
	-- 				end,
	-- 			},
	-- 		})
	-- 	end,
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 	},
	-- },
	{
		"mhartington/formatter.nvim",
		config = function()
			require("core.plugins.configs").formatter()
		end,
	},

	-- loadsnips + cmp related in insert mode only
	{ "rafamadriz/friendly-snippets", event = "InsertEnter" },

	{
		"hrsh7th/nvim-cmp",
		config = function()
			require("core.plugins._cmp")
		end,
	},

	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			"williamboman/mason.nvim",
		},
		config = function()
			require("core.plugins._dap")
		end,
	},

	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets", event = "InsertEnter" },
		config = function()
			require("core.plugins.configs").luasnip()
		end,
	},

	-- cmp sources
	"saadparwaiz1/cmp_luasnip",
	"hrsh7th/cmp-nvim-lua",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",

	-- misc plugins
	{
		"windwp/nvim-autopairs",
		config = function()
			require("core.plugins.configs").autopairs()
		end,
	},

	{
		"goolord/alpha-nvim",
		config = function()
			require("core.plugins._alpha")
		end,
	},

	{
		"numToStr/Comment.nvim",
		keys = { "gc", "gb" },
		config = function()
			require("core.plugins.configs").comment()
		end,
		init = function()
			require("core.utils").load_mappings("comment")
		end,
	},

	-- file managing , picker etc
	{
		"nvim-tree/nvim-tree.lua",
		ft = "alpha",
		cmd = { "NvimTreeToggle", "NvimTreeFocus" },
		config = function()
			require("core.plugins._nvimtree")
		end,
		init = function()
			require("core.utils").load_mappings("nvimtree")
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-telescope/telescope-live-grep-args.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			require("core.plugins._telescope")
		end,
		init = function()
			require("core.utils").load_mappings("telescope")
		end,
	},

	-- Only load whichkey
	{
		"folke/which-key.nvim",
		keys = "<leader>",
		config = function()
			require("core.plugins._whichkey")
		end,
		init = function()
			require("core.utils").load_mappings("whichkey")
		end,
	},

	-- theme related
	{ "jwbaldwin/moonlight-material.vim", lazy = true },
	{
		"jwbaldwin/tokyonight.nvim",
		dir = "~/repos/tokyonight.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			require("core.plugins._tokyonight")
		end,
	},

	-- utility
	{
		"ThePrimeagen/harpoon",
		config = function()
			require("core.plugins.configs").harpoon()
		end,
	},

	"tpope/vim-surround",
	"tpope/vim-projectionist",
	"vim-test/vim-test",
	{
		"rcarriga/nvim-notify",
		config = function()
			require("core.plugins.configs").notify()
		end,
	},
	-- { "nvim-neotest/neotest-vim-test", lazy = true },
	"antoinemadec/FixCursorHold.nvim",
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"jfpedroza/neotest-elixir",
		},
		config = function()
			require("core.plugins._neotest")
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("core.plugins._projects")
		end,
	},
	{
		"numToStr/FTerm.nvim",
		config = function()
			require("core.plugins._fterm")
		end,
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = require("core.plugins.configs").flash.otps,
		keys = require("core.plugins.configs").flash.keys,
	},
	-- {
	--   "ggandor/leap.nvim",
	--   config = function()
	--     require("core.plugins._leap")
	--   end,
	-- },
	{
		"mg979/vim-visual-multi",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-m>",
			}
		end,
	},

	-- ui plugins
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("core.plugins._lualine")
		end,
	},
	{
		"folke/todo-comments.nvim",
		config = function()
			require("core.plugins.configs").todo()
		end,
	},
	"tpope/vim-fugitive",
	"github/copilot.vim",
})
