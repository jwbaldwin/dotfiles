local M = {}

local function find_local_node_bin(cmd, dir)
	if not dir or dir == "" then
		return nil
	end

	return vim.fs.find("node_modules/.bin/" .. cmd, {
		upward = true,
		path = dir,
		type = "file",
		limit = 1,
	})[1]
end

local function js_formatters(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local local_oxfmt = find_local_node_bin("oxfmt", vim.fs.dirname(bufname))
	if local_oxfmt then
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
			command = function(self, ctx)
				return find_local_node_bin("oxfmt", ctx.dirname) or self.command
			end,
			condition = function(_, ctx)
				return find_local_node_bin("oxfmt", ctx.dirname) ~= nil
			end,
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
