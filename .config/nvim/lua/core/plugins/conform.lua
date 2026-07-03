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

local function has_executable(cmd)
	return vim.fn.executable(cmd) == 1
end

local function format_on_save(bufnr)
	if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
		return nil
	end

	return {
		lsp_format = "never",
		stop_after_first = true,
		timeout_ms = 2000,
	}
end

local function js_formatters(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local dirname = vim.fs.dirname(bufname)
	local local_oxfmt = find_local_node_bin("oxfmt", dirname)
	if local_oxfmt then
		return { "oxfmt" }
	end
	if has_executable("prettierd") then
		return { "prettierd" }
	end
	if has_executable("prettier") then
		return { "prettier" }
	end
	if has_executable("oxfmt") then
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
			command = function(_, ctx)
				return find_local_node_bin("oxfmt", ctx.dirname) or "oxfmt"
			end,
			condition = function(_, ctx)
				return find_local_node_bin("oxfmt", ctx.dirname) ~= nil or has_executable("oxfmt")
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
	format_on_save = format_on_save,
	notify_on_error = true,
	notify_no_formatters = true,
}

return M
