local M = {}

M.todo = function()
	local present, todo = pcall(require, "todo-comments")

	if not present then
		return
	end

	todo.setup()
end

M.persisted = function()
	local present, persisted = pcall(require, "persisted")

	if not present then
		return
	end

	local options = {
		save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"), -- directory where session files are saved
		command = "VimLeavePre", -- the autocommand for which the session is saved
		silent = false, -- silent nvim message when sourcing session file
		use_git_branch = true, -- create session files based on the branch of the git enabled repository
		branch_separator = "_", -- string used to separate session directory name from branch name
		autosave = true, -- automatically save session files when exiting Neovim
		autoload = false, -- automatically load the session for the cwd on Neovim startup
		on_autoload_no_session = nil, -- function to run when `autoload = true` but there is no session to load
		allowed_dirs = nil, -- table of dirs that the plugin will auto-save and auto-load from
		ignored_dirs = nil, -- table of dirs that are ignored when auto-saving and auto-loading
		before_save = nil, -- function to run before the session is saved to disk
		after_save = nil, -- function to run after the session is saved to disk
		after_source = nil, -- function to run after the session is sourced
		telescope = {
			-- options for the telescope extension
			before_source = nil, -- function to run before the session is sourced via telescope
			after_source = nil, -- function to run after the session is sourced via telescope
		},
	}

	persisted.setup(options)
end

M.autopairs = function()
	local present1, autopairs = pcall(require, "nvim-autopairs")

	local options = {
		fast_wrap = {},
		disable_filetype = { "TelescopePrompt", "vim" },
	}

	autopairs.setup(options)
end

M.blankline = function()
	local present, blankline = pcall(require, "indent_blankline")

	if not present then
		return
	end

	local options = {
		indentLine_enabled = 1,
		filetype_exclude = {
			"help",
			"terminal",
			"alpha",
			"lspinfo",
			"TelescopePrompt",
			"TelescopeResults",
			"mason",
			"",
		},
		buftype_exclude = { "terminal" },
		show_trailing_blankline_indent = false,
		show_first_indent_level = false,
		show_current_context = true,
		show_current_context_start = false,
	}

	blankline.setup(options)
end

M.devicons = function()
	local present, devicons = pcall(require, "nvim-web-devicons")

	if present then
		-- local options = { override = require("core.icons").devicons }
		local options = {}

		devicons.setup(options)
	end
end

M.toggleterm = {
	opts = {
		start_in_insert = true,
		highlights = {
			-- NormalFloat = { guibg = "#1a1b26" }, -- tokyonight
			-- FloatBorder = { guifg = "#9ece6a", -- tokyonight
			NormalFloat = { guibg = "NONE" },
			FloatBorder = { guifg = "#9ece6a", guibg = "NONE" },
		},
		size = function(term)
			if term.direction == "horizontal" then
				return vim.o.lines * 0.4
			elseif term.direction == "vertical" then
				return vim.o.columns * 0.4
			end
		end,
		float_opts = {
			border = "curved",
			width = function(_term)
				return math.ceil(math.max(40, vim.o.columns * 0.55))
			end,
			height = function(_term)
				return math.ceil(math.max(40, vim.o.lines * 0.7))
			end,
			winblend = 10,
		},
	},
}

M.flash = {
	opts = {},
	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump({
					-- search = {
					--   mode = function(str)
					--     return "\\<" .. str
					--   end,
					-- },
					jump = {
						autojump = true,
					},
				})
			end,
			desc = "Flash",
		},
		-- {
		--   "S",
		--   mode = { "n", "o", "x" },
		--   function()
		--     require("flash").treesitter()
		--   end,
		--   desc = "Flash Treesitter",
		-- },
		{
			"r",
			mode = "o",
			function()
				require("flash").remote()
			end,
			desc = "Remote Flash",
		},
		{
			"R",
			mode = { "o", "x" },
			function()
				require("flash").treesitter_search()
			end,
			desc = "Flash Treesitter Search",
		},
		{
			"<c-s>",
			mode = { "c" },
			function()
				require("flash").toggle()
			end,
			desc = "Toggle Flash Search",
		},
	},
}

return M
