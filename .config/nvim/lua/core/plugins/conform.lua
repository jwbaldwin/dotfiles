local M = {}

M.opts = {
	formatters_by_ft = {
		lua = { "stylua" },
		elixir = { "mix" },
		go = { "gofmt" },
		javascript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
		typescript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
		markdown = {}, -- Marksman doesn't support formatting, skip LSP fallback
	},
	formatters = {
		oxfmt = {
			cwd = function()
				-- Run from project root so oxfmt can find node_modules/.bin/
				local root = vim.fs.find({ "package.json", ".git" }, { upward = true, path = vim.fn.expand("%:p:h") })[1]
				return root and vim.fn.fnamemodify(root, ":h") or vim.fn.getcwd()
			end,
		},
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	notify_on_error = true,
}

return M
