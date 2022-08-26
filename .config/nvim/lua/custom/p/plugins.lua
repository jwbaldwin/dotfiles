return {
  ["jwbaldwin/moonlight-material.vim"] = {},
  ["tpope/vim-surround"] = {},
  ["vim-test/vim-test"] = {},
  ["rcarriga/nvim-notify"] = {},
  ["ThePrimeagen/harpoon"] = {},
  ["ahmedkhalf/project.nvim"] = {
    config = function()
      require "custom.p.projects"
    end,
  },
  ["jose-elias-alvarez/null-ls.nvim"] = {
    after = "nvim-lspconfig",
    config = function()
      require "custom.p.null-ls"
    end,
  },
  ["numToStr/FTerm.nvim"] = {
    config = function()
      require "custom.p.fterm"
    end,
  },
  ["ggandor/lightspeed.nvim"] = {
    config = function()
      require "custom.p.lightspeed"
    end,
  },
  ["goolord/alpha-nvim"] = {
    disable = false,
    config = function()
      require "custom.p.alpha"
    end,
  },
  ["rmagatti/session-lens"] = {
    after = "auto-session",
  },
  ["rmagatti/auto-session"] = {
    after = "telescope.nvim",
    config = function()
      require "custom.p.session"
    end,
  },
  ["nvim-telescope/telescope.nvim"] = {
    config = function()
      require "custom.p.telescope"
    end,
  },
  ["nvim-telescope/telescope-fzf-native.nvim"] = {
    run = "make",
  },
  ["folke/which-key.nvim"] = {
    disable = false,
  },
  ["neovim/nvim-lspconfig"] = {
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.p.lspconfig"
    end,
  },
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
  },
}
