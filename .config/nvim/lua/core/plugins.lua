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
	{
		"dmtrKovalenko/fff.nvim",
		build = require("core.plugins.fff").build,
		opts = require("core.plugins.fff").opts,
		lazy = false,
		keys = require("core.plugins.fff").keys,
	},
	"nvim-lua/plenary.nvim",
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
	{
		"julienvincent/hunk.nvim",
		cmd = { "DiffEditor" },
		config = function()
			require("hunk").setup()
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
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = require("core.plugins.conform").opts,
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
	{ "rebelot/kanagawa.nvim" },
	{ "savq/melange-nvim" },
	{ "xero/miasma.nvim" },
	{
		"luisiacc/gruvbox-baby",
		branch = "main",
		lazy = false,
		priority = 10000,
		config = function()
			vim.g.gruvbox_baby_background_color = "dark"
			vim.g.gruvbox_baby_transparent_mode = true
			vim.g.gruvbox_baby_comment_style = "italic"
			vim.g.gruvbox_baby_keyword_style = "italic"
			vim.g.gruvbox_baby_function_style = "NONE"
			vim.g.gruvbox_baby_variable_style = "NONE"

			-- vim.cmd("colorscheme gruvbox-baby")
		end,
	},
	{ "ramojus/mellifluous.nvim" },
	{ "datsfilipe/vesper.nvim" },
	{ "aliqyan-21/darkvoid.nvim" },

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
	"tpope/vim-abolish",
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
		commit = "da369d9", -- Pin to 1.56.0 - 1.57.0 causes immediate exit
		cond = function()
			return os.getenv("USER") == "jbaldwin" and os.getenv("WORK") == "true"
		end,
		init = function()
			vim.g.copilot_node_command = vim.fn.expand("~/.local/share/mise/installs/node/22.20.0/bin/node")
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
			return os.getenv("USER") == "jbaldwin" and (os.getenv("WORK") == nil or os.getenv("WORK") == "false")
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
		"folke/sidekick.nvim",
		lazy = false,
		opts = {
			cli = {
				mux = {
					backend = "tmux",
					enabled = true,
				},
			},
		},
		keys = {
			{
				"<tab>",
				function()
					-- if there is a next edit, jump to it, otherwise apply it if any
					if not require("sidekick").nes_jump_or_apply() then
						return "<Tab>" -- fallback to normal tab
					end
				end,
				expr = true,
				desc = "Goto/Apply Next Edit Suggestion",
			},
			{
				"<leader>aa",
				function()
					require("sidekick.cli").toggle()
				end,
				desc = "Sidekick Toggle CLI",
			},
			{
				"<leader>as",
				function()
					require("sidekick.cli").select({ filter = { installed = true } })
				end,
				desc = "Select CLI",
			},
			{
				"<leader>at",
				function()
					require("sidekick.cli").send({ msg = "{this}" })
				end,
				mode = { "x", "n" },
				desc = "Send This",
			},
			{
				"<leader>av",
				function()
					require("sidekick.cli").send({ msg = "{selection}" })
				end,
				mode = { "x" },
				desc = "Send Visual Selection",
			},
			{
				"<leader>ap",
				function()
					require("sidekick.cli").prompt()
				end,
				mode = { "n", "x" },
				desc = "Sidekick Select Prompt",
			},
			{
				"<c-.>",
				function()
					require("sidekick.cli").focus()
				end,
				mode = { "n", "x", "i", "t" },
				desc = "Sidekick Switch Focus",
			},
			{
				"<leader>ac",
				function()
					require("sidekick.cli").toggle({ name = "opencode", focus = true })
				end,
				desc = "Sidekick Toggle Opencode",
			},
		},
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
					model = "claude-sonnet-4-5-20250929",
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
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
		keys = {
			{
				"<leader>ae",
				function()
					require("avante.api").edit()
				end,
				desc = "Avante: Edit selection",
				mode = "v",
			},
		},
	},
})
