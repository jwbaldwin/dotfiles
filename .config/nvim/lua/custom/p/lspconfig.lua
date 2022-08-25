-- custom.plugins.lspconfig
local capabilities = require("plugins.configs.lspconfig").capabilities
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

  require("core.utils").load_mappings("lspconfig", { buffer = bufnr })
  vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format({bufnr = bufnr})]]

  if client.server_capabilities.signatureHelpProvider then
    require("nvchad_ui.signature").setup(client)
  end
end

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "jsonls", "tailwindcss", "bashls", "sumneko_lua" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }
end

lspconfig.elixirls.setup {
  cmd = { "/Users/jbaldwin/repos/elixir-ls/release/language_server.sh" },
  on_attach = default_on_attach,
  capabilities = capabilities,
  settings = {
    elixirLS = {
      dialyzerEnabled = false,
      fetchDeps = false,
    },
  },
}
