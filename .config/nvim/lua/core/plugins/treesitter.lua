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

-- Check nvim-treesitter's parser dir specifically, not Neovim's bundled parsers,
-- to avoid stale bundled parsers mismatching nvim-treesitter's query files.
local parser_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser"

local function has_installed_parser(lang)
	return vim.uv.fs_stat(parser_dir .. "/" .. lang .. ".so") ~= nil
end

local to_install = vim.tbl_filter(function(lang)
	return not has_installed_parser(lang)
end, ensure_installed)

if #to_install > 0 and vim.fn.executable("tree-sitter") == 1 then
	require("nvim-treesitter").install(to_install)
end

-- Neovim's auto-start can be disrupted by plugin load order, so explicitly enable it
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
