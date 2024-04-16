require("project_nvim").setup({
	manual_mode = false,
	detection_methods = { "lsp", "pattern" },
	patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },
	ignore_lsp = {},
	-- Don't calculate root dir on specific directories
	-- Ex: { "~/.cargo/*", ... }
	exclude_dirs = { "~", "deps/*", "node_modules/*", "assets/*" },
	-- Show hidden files in telescope
	show_hidden = false,
	-- When set to false, you will get a message when project.nvim changes your
	-- directory.
	silent_chdir = false,
	-- Path where project.nvim will store the project history for use in
	-- telescope
	datapath = vim.fn.stdpath("data"),
})
