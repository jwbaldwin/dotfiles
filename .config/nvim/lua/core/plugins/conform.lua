local M = {}

local function has_oxfmt(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local dir = vim.fs.dirname(bufname)
	if not dir or dir == "" then
		return vim.fn.executable("oxfmt") == 1
	end
	local found = vim.fs.find("node_modules/.bin/oxfmt", {
		upward = true,
		path = dir,
		type = "file",
		limit = 1,
	})
	if #found > 0 then
		return true
	end
	return vim.fn.executable("oxfmt") == 1
end

local function js_formatters(bufnr)
	if has_oxfmt(bufnr) then
		return { "oxfmt" }
	end
	return { "prettierd", "prettier" }
end


M.opts = {
	formatters_by_ft = {
		lua = { "stylua" },
		elixir = { "mix" },
		go = { "gofmt" },
		javascript = js_formatters,
		typescript = js_formatters,
		javascriptreact = js_formatters,
		typescriptreact = js_formatters,
		markdown = {},
	},
	formatters = {
		oxfmt = {
			inherit = true,
			stdin = false,
			args = { "$FILENAME" },
		},
	},
	default_format_opts = {
		lsp_format = "never",
		stop_after_first = true,
		timeout_ms = 2000,
	},
	format_on_save = true,
	notify_on_error = true,
	notify_no_formatters = true,
}

return M
