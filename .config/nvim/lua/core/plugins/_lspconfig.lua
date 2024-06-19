local lspconfig = require("lspconfig")
local configs = require("lspconfig.configs")
local utils = require("core.utils")

local username = os.getenv("USER")

if username == "james.baldwin" then
	username = "jwbaldwin"
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem = {
	documentationFormat = { "markdown", "plaintext" },
	snippetSupport = true,
	preselectSupport = true,
	insertReplaceSupport = true,
	labelDetailsSupport = true,
	deprecatedSupport = true,
	commitCharactersSupport = true,
	tagSupport = { valueSet = { 1 } },
	resolveSupport = {
		properties = {
			"documentation",
			"detail",
			"additionalTextEdits",
		},
	},
}

local default_on_attach = function(client, bufnr)
	if vim.g.vim_version > 7 then
		-- nightly
		client.server_capabilities.documentFormattingProvider = true
		client.server_capabilities.documentRangeFormattingProvider = true
	else
		-- stable
		client.resolved_capabilities.document_formatting = true
		client.resolved_capabilities.document_range_formatting = true
	end

	utils.load_mappings("lspconfig", { buffer = bufnr })

	-- vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format({bufnr = bufnr})]]
end

local servers = { "html", "cssls", "jsonls", "bashls", "tsserver", "svelte", "marksman", "tailwindcss" }

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = default_on_attach,
		capabilities = capabilities,
	})
end

lspconfig.lua_ls.setup({
	on_attach = default_on_attach,
	capabilities = capabilities,

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
})

lspconfig.emmet_language_server.setup({
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
})

local elixirls = ""
if os.getenv("USER") == "jbaldwin" then
	elixirls = "/Users/jbaldwin/.local/share/nvim/mason/packages/elixir-ls/language_server.sh"
else
	-- Mason's install location
	elixirls = "/Users/jwbaldwin/.local/share/nvim/mason/packages/elixir-ls/language_server.sh"
end

lspconfig.elixirls.setup({
	cmd = { elixirls },
	on_attach = default_on_attach,
	capabilities = capabilities,
	filetypes = { "elixir", "eelixir", "heex", "surface", "eex" },
	settings = {
		elixirLS = {
			dialyzerEnabled = false,
			fetchDeps = true,
		},
	},
})

-- Lexical
-- local lexical_config = {
-- 	filetypes = { "elixir", "eelixir", "heex", "eex", "surface" },
-- 	cmd = { "/Users/" .. username .. "/.local/share/nvim/mason/bin/lexical", "server" },
-- 	root_dir = require("lspconfig.util").root_pattern({ "mix.exs" }),
-- 	settings = {},
-- }
--
-- if not configs.lexical then
-- 	configs.lexical = {
-- 		default_config = {
-- 			filetypes = lexical_config.filetypes,
-- 			cmd = lexical_config.cmd,
-- 			root_dir = function(fname)
-- 				return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
-- 			end,
-- 			-- optional settings
-- 			settings = lexical_config.settings,
-- 		},
-- 	}
-- end
--
-- lspconfig.lexical.setup({})
