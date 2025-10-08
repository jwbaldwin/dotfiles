local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

local default_on_attach = function(client, bufnr)
	if vim.g.vim_version > 7 then
		client.server_capabilities.documentFormattingProvider = true
		client.server_capabilities.documentRangeFormattingProvider = true
	else
		client.resolved_capabilities.document_formatting = true
		client.resolved_capabilities.document_range_formatting = true
	end

	require("core.utils").load_mappings("lspconfig", { buffer = bufnr })
end

local servers = { "html", "cssls", "jsonls", "bashls", "ts_ls", "svelte", "tailwindcss", "gopls", "marksman", "prismals" }

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

if os.getenv("WORK") == "true" then
	local copilot_config = dofile(vim.fn.expand("~/.local/share/nvim/lazy/nvim-lspconfig/lsp/copilot.lua"))
	copilot_config.cmd = { vim.fn.expand("~/.local/share/mise/installs/node/22.20.0/bin/node"), vim.fn.expand("~/.local/share/nvim/lazy/copilot.vim/copilot-language-server/dist/language-server.js"), "--stdio" }
	vim.lsp.config.copilot = copilot_config
	vim.lsp.enable("copilot")
end
