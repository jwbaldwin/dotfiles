local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

vim.lsp.handlers["textDocument/willSaveWaitUntil"] = function()
	return {}
end

local default_on_attach = function(client, bufnr)
	-- Disable LSP formatting for servers where a dedicated formatter (conform.nvim) handles it.
	-- Force-enabling this was causing ts_ls to truncate files when conform fell through to lsp_format = "fallback".
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.documentRangeFormattingProvider = false
	client.server_capabilities.documentOnTypeFormattingProvider = false
	client.handlers["textDocument/willSaveWaitUntil"] = function()
		return {}
	end

	require("core.utils").load_mappings("lspconfig", { buffer = bufnr })
end

local servers = { "html", "cssls", "jsonls", "bashls", "ts_ls", "tailwindcss", "gopls", "marksman", "prismals" }

for _, lsp in ipairs(servers) do
	local config = vim.lsp.config[lsp] or {}
	config.on_attach = default_on_attach
	config.capabilities = capabilities
	vim.lsp.config[lsp] = config
	vim.lsp.enable(lsp)
end

vim.lsp.config.lua_ls = {
	capabilities = capabilities,
	on_attach = default_on_attach,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "require" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
				},
				maxPreload = 100000,
				preloadFileSize = 10000,
			},
		},
	},
}
vim.lsp.enable("lua_ls")

vim.lsp.config.emmet_language_server = {
	capabilities = capabilities,
	on_attach = default_on_attach,
	filetypes = {
		"css",
		"html",
		"javascript",
		"javascriptreact",
		"less",
		"sass",
		"scss",
		"typescriptreact",
		"eelixir",
	},
}
vim.lsp.enable("emmet_language_server")

local lexical_config = {
	filetypes = { "elixir", "eelixir", "heex", "eex", "surface" },
	cmd = { "/Users/" .. os.getenv("USER") .. "/.local/share/nvim/mason/bin/lexical", "server" },
	root_markers = { "mix.exs" },
	capabilities = capabilities,
	on_attach = default_on_attach,
	settings = {},
}

vim.lsp.config.lexical = lexical_config
vim.lsp.enable("lexical")

-- copilot.vim plugin handles its own LSP server, no need to configure here
