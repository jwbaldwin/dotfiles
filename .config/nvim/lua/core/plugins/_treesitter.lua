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
		"heex",
		"html",
		"lua",
		"markdown",
		"markdown_inline",
		"norg",
		"tsx",
		"typescript",
		"yaml",
		"svelte",
	},
	highlight = {
		enable = true,
	},
}

treesitter.setup(options)
