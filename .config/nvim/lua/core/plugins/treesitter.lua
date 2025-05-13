local present, treesitter = pcall(require, "nvim-treesitter.configs")

if not present then
	return
end

local options = {
	playground = {
		enable = true,
		disable = {},
		updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
		persist_queries = false, -- Whether the query persists across vim sessions
	},
	ensure_installed = {
		"bash",
		"css",
		"eex",
		"elixir",
		"erlang",
		"go",
		"heex",
		"html",
		"lua",
		"norg",
		"svelte",
		"tsx",
		"typescript",
		"vim",
		"vimdoc",
		"yaml",
	},
	highlight = {
		enable = true,
	},
}

treesitter.setup(options)
