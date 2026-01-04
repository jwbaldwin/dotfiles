local M = {}

M.opts = {
	formatters_by_ft = {
		lua = { "stylua" },
		elixir = { "mix" },
		go = { "gofmt" },
		javascript = { "oxfmt", "oxlint", "prettierd", "prettier", stop_after_first = true },
		typescript = { "oxfmt", "oxlint", "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "oxfmt", "oxlint", "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "oxfmt", "oxlint", "prettierd", "prettier", stop_after_first = true },
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	notify_on_error = true,
}

return M
