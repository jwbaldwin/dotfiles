local present, treesitter = pcall(require, "nvim-treesitter.configs")

if not present then
	return
end

local options = {
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
