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
			command = "oxfmt",
			args = { "--stdin-filepath", "$FILENAME" },
			stdin = true,
		},
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	notify_on_error = true,
}

return M
