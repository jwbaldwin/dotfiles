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
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = require("core.plugins.snacks").opts,
		keys = require("core.plugins.snacks").keys,
		init = require("core.plugins.snacks").init(),
	},
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
			require("core.plugins.treesitter")
		end,
	},
	{ "nvim-treesitter/playground", event = "VeryLazy" },
	-- git stuff
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPre",
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "│" },
					change = { text = "│" },
				},
			})
		end,
	},

	-- lsp stuff
	{
		"williamboman/mason.nvim",
		cmd = require("core.utils").mason_cmds,
		config = function()
			require("core.plugins.mason")
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"williamboman/mason.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			require("core.plugins.lspconfig")
		end,
	},
	{
		"mhartington/formatter.nvim",
		config = function()
			require("core.plugins.configs").formatter()
		end,
	},

	-- nvim.cmp + snippets replacement
	{
		"saghen/blink.cmp",
		version = "*",
		event = "LspAttach",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		opts = require("core.plugins.blink").opts,
		opts_extend = require("core.plugins.blink").opts_extend,
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
			require("core.plugins.dap")
		end,
	},
	-- misc plugins
	{
		"windwp/nvim-autopairs",
		config = function()
			require("core.plugins.configs").autopairs()
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
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-telescope/telescope-live-grep-args.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		config = function()
			require("core.plugins.telescope")
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
			require("core.plugins.whichkey")
		end,
		init = function()
			require("core.utils").load_mappings("whichkey")
		end,
	},

	-- theme related
	{
		"brenoprata10/nvim-highlight-colors",
		init = function()
			require("nvim-highlight-colors").setup({})
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 10000, -- make sure to load this before all the other start plugins
		config = function()
			require("core.plugins.tokyonight")
		end,
		init = function()
			vim.cmd([[colorscheme tokyonight]])
		end,
	},
	-- {
	-- 	-- "jwbaldwin/oscura.nvim",
	-- 	dir = "~/repos/oscura.nvim",
	-- 	branch = "color-tweaks-and-fixes",
	-- 	lazy = false,
	-- 	priority = 10000,
	-- 	config = function()
	-- 		require("oscura").setup()
	-- 	end,
	-- 	init = function()
	-- 		vim.cmd([[colorscheme oscura]])
	-- 	end,
	-- },
	{
		"olivercederborg/poimandres.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("poimandres").setup({
				-- leave this setup function empty for default config
				-- or refer to the configuration section
				-- for configuration options
			})
		end,
		init = function()
			-- vim.cmd([[colorscheme poimandres]])
		end,
	},
	{
		"gmr458/cold.nvim",
		lazy = false,
		priority = 1000,
		build = ":ColdCompile",
		config = function()
			require("cold").setup({
				transparent_background = false,
				cursorline = false,
				treesitter_context_bg = false,
				float_borderless = false,
			})
			-- vim.cmd.colorscheme("cold")
		end,
	},

	-- utility
	{
		"ThePrimeagen/harpoon",
		-- branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("core.plugins.configs").harpoon()
		end,
	},
	"mg979/vim-visual-multi",
	"tpope/vim-surround",
	"tpope/vim-projectionist",
	"andyl/vim-projectionist-elixir",
	"vim-test/vim-test",
	"antoinemadec/FixCursorHold.nvim",
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("core.plugins.projects")
		end,
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = require("core.plugins.configs").flash.otps,
		keys = require("core.plugins.configs").flash.keys,
	},
	{ "nvim-pack/nvim-spectre" },
	{
		"smjonas/inc-rename.nvim",
		config = function()
			require("inc_rename").setup()
		end,
	},
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		opts = require("core.plugins.configs").toggleterm.opts,
		dependencies = { "jwbaldwin/tokyonight.nvim" },
	},
	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
			"TmuxNavigatorProcessList",
		},
		keys = {
			{ "<leader>h", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<leader>j", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<leader>k", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<leader>l", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<leader>p", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},

	-- ui plugins
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("core.plugins.lualine")
		end,
	},
	{
		"folke/todo-comments.nvim",
		config = function()
			require("core.plugins.configs").todo()
		end,
	},
	"tpope/vim-fugitive",
	"shumphrey/fugitive-gitlab.vim",
	{
		"github/copilot.vim",
		cond = function()
			return os.getenv("USER") == "jwbaldwin" or os.getenv("USER") == "james.baldwin"
		end,
	},
	{
		"stevearc/oil.nvim",
		opts = {},
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("core.plugins.oil")
		end,
	},

	-- AI stuff
	{
		"supermaven-inc/supermaven-nvim",
		cond = function()
			return os.getenv("USER") == "jbaldwin"
		end,
		config = function()
			require("supermaven-nvim").setup({
				keymaps = {
					accept_suggestion = "<C-y>",
					clear_suggestion = "<C-x>",
					accept_word = "<C-w>",
				},
				disable_keymaps = false,
			})
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		opts = {},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "anthropic",
					},
					inline = {
						adapter = "anthropic",
					},
				},
			})
		end,
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		opts = {
			provider = "claude",
			providers = {
				claude = {
					endpoint = "https://api.anthropic.com",
					model = "claude-sonnet-4-20250514",
				},
			},
			disabled_tools = { "python", "git_commit" },
		},
		build = "make",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
})
