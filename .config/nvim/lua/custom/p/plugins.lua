return {
    ["jwbaldwin/moonlight-material.vim"] = {},
    ["tpope/vim-surround"] = {},
    ["vim-test/vim-test"] = {},
    ["nvim-telescope/telescope-project.nvim"] = {},
    ["rcarriga/nvim-notify"] = {},
    ["ThePrimeagen/harpoon"] = {},
    ["numToStr/FTerm.nvim"] = {
      config = function()
        require "custom.p.fterm"
      end
    },
    ["ggandor/lightspeed.nvim"] = {
      config = function()
        require "custom.p.lightspeed"
      end
    },
    ["goolord/alpha-nvim"] = {
        disable = false,
        config = function()
          require "custom.p.alpha"
        end,
    },
    ["rmagatti/session-lens"] = {
      after = "auto-session"
    },
    ["rmagatti/auto-session"] = {
      after = "telescope.nvim",
      config = function()
        require "custom.p.session"
      end
    },
    ["nvim-telescope/telescope.nvim"] = {
        config = function()
          require "custom.p.telescope"
        end,
    },
    ["nvim-telescope/telescope-fzf-native.nvim"] = {
      run = "make"
    },
    ["folke/which-key.nvim"] = {
      disable = false
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
