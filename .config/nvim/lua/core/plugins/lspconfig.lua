-- Shared capabilities (blink.cmp completion support)
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

-- Apply shared capabilities to all servers via wildcard
vim.lsp.config("*", {
	capabilities = capabilities,
})

-- Suppress willSaveWaitUntil globally
vim.lsp.handlers["textDocument/willSaveWaitUntil"] = function()
	return {}
end

-- Shared on_attach behavior for all LSP servers
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end

		-- Disable LSP formatting — conform.nvim handles it
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
		client.server_capabilities.documentOnTypeFormattingProvider = false

		client.handlers["textDocument/willSaveWaitUntil"] = function()
			return {}
		end

		-- Buffer-local LSP keymaps
		require("core.utils").load_mappings("lspconfig", { buffer = args.buf })
	end,
})

-- Server-specific settings (only needed for servers that need custom config)
-- mason-lspconfig auto-enables all Mason-installed servers with lspconfig defaults.

vim.lsp.config.lua_ls = {
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

vim.lsp.config.emmet_language_server = {
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
