local lspconfig = require("lspconfig")
local configs = require("lspconfig.configs")

local utils = require("core.utils")

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

local servers = { "html", "cssls", "jsonls", "bashls", "tsserver", "eslint", "tailwindcss", "svelte", "marksman" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = default_on_attach,
    capabilities = capabilities,
  }
end

lspconfig.lua_ls.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,

  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim", "require" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
}

-- local elixirls = ""
-- if os.getenv("USER") == "jbaldwin" then
--   elixirls = "/Users/jbaldwin/.local/share/nvim/mason/packages/elixir-ls/language_server.sh"
-- else
--   -- Mason's install location
--   elixirls = "/Users/jwbaldwin/.local/share/nvim/mason/packages/elixir-ls/language_server.sh"
-- end
--
-- lspconfig.elixirls.setup {
--   cmd = { elixirls },
--   on_attach = default_on_attach,
--   capabilities = capabilities,
--   filetypes = { "elixir", "eelixir", "heex", "surface", "eex" },
--   settings = {
--     elixirLS = {
--       dialyzerEnabled = false,
--       fetchDeps = true,
--     },
--   },
-- }

-- Lexical
local lexical_config = {
  filetypes = { "elixir", "eelixir", "heex", "eex", "surface" },
  cmd = { "/Users/jwbaldwin/repos/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
  settings = {},
}

if not configs.lexical then
  configs.lexical = {
    default_config = {
      filetypes = lexical_config.filetypes,
      cmd = lexical_config.cmd,
      root_dir = function(fname)
        return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
      end,
      -- optional settings
      settings = lexical_config.settings,
    },
  }
end

lspconfig.lexical.setup({})

lspconfig.tailwindcss.setup {
  on_attach = default_on_attach,
  capabilities = capabilities,
  init_options = {
    userLanguages = {
      heex = "phoenix-heex",
    },
  },
  handlers = {
    ["tailwindcss/getConfiguration"] = function(_, _, params, _, bufnr, _)
      vim.lsp.buf_notify(bufnr, "tailwindcss/getConfigurationResponse", { _id = params._id })
    end,
  },
  root_dir = lspconfig.util.root_pattern('tailwind.config.js', 'tailwind.config.ts', 'postcss.config.js',
    'postcss.config.ts',
    'package.json',
    'node_modules', '.git'),
  settings = {
    includeLanguages = {
      typescript = "javascript",
      typescriptreact = "javascript",
      ["html-eex"] = "html",
      ["phoenix-heex"] = "html",
      heex = "html",
      eelixir = "html",
    },
    tailwindCSS = {
      lint = {
        invalidApply = "error",
        invalidConfigPath = "error",
        invalidScreen = "error",
        invalidTailwindDirective = "error",
        invalidVariant = "error",
        recommendedVariantOrder = "warning",
      },
      experimental = {
        classRegex = {
          [[class= "([^"]*)]],
          [[class: "([^"]*)]],
          '~H""".*class="([^"]*)".*"""',
        },
      },
      validate = true,
    },
  },
  filetypes = {
    -- "css",
    -- "scss",
    -- "sass",
    "html",
    "heex",
    "svelte",
    -- "elixir",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
}
