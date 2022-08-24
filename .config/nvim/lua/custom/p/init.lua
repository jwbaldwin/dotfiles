return {
    ["goolord/alpha-nvim"] = {
      disable = false,
    },
    ["folke/which-key.nvim"] = {
      disable = false
    },
    ["rcarriga/nvim-notify"] = {},
    ["williamboman/mason.nvim"] = {
      ensure_installed = {
        -- lua stuff
        "lua-language-server",
        "stylua",
        -- elixir
        "elixir-ls",
        "yamllint",
        "yaml-language-server",

        -- web dev
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "typescript-language-server",
        "json-lsp",

        -- shell
        "shfmt",
    },
}
