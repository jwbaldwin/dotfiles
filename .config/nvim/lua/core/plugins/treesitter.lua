local ensure_installed = {
	"bash",
	"css",
	"eex",
	"elixir",
	"erlang",
	"go",
	"heex",
	"html",
	"lua",
	"svelte",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

-- Install missing parsers (async)
local installed = require("nvim-treesitter").get_installed()
local to_install = vim.tbl_filter(function(lang)
	return not vim.list_contains(installed, lang)
end, ensure_installed)

if #to_install > 0 then
	require("nvim-treesitter").install(to_install)
end

-- Neovim's auto-start can be disrupted by plugin load order, so explicitly enable it
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
