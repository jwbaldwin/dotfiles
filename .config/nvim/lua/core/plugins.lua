local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer...close and reopen Neovim"
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Configure packer popup
local options = require("core.plugins.configs").packer
packer.init(options)

-- plugins here
return packer.startup(function(use)
  -- base
  use { "nvim-lua/plenary.nvim", module = "plenary" }
  use { "wbthomason/packer.nvim", cmd = require("core.utils").packer_cmds }
  use { "kyazdani42/nvim-web-devicons",
    module = "nvim-web-devicons",
    config = function()
      require("core.plugins.configs").devicons()
    end,
  }
  use { "lukas-reineke/indent-blankline.nvim",
    opt = true,
    setup = function()
      require("core.utils").on_file_open "indent-blankline.nvim"
      require("core.utils").load_mappings "blankline"
    end,
    config = function()
      require("core.plugins.configs").blankline()
    end,
  }
  use { "nvim-treesitter/nvim-treesitter",
    module = "nvim-treesitter",
    setup = function()
      require("core.utils").on_file_open "nvim-treesitter"
    end,
    cmd = require("core.utils").treesitter_cmds,
    run = ":TSUpdate",
    config = function()
      require "core.plugins.treesitter"
    end,
  }

  -- git stuff
  use { "lewis6991/gitsigns.nvim",
    ft = "gitcommit",
    setup = function()
      require("core.utils").gitsigns()
    end,
    config = function()
      require("core.plugins.configs").gitsigns()
    end,
  }

  -- lsp stuff
  use { "williamboman/mason.nvim",
    cmd = require("core.utils").mason_cmds,
    config = function()
      require "core.plugins.mason"
    end,
  }
  use { "neovim/nvim-lspconfig",
    opt = true,
    setup = function()
      require("core.utils").on_file_open "nvim-lspconfig"
    end,
    config = function()
      require "core.plugins.lspconfig"
    end,
  }

  -- load luasnips + cmp related in insert mode only
  use { "rafamadriz/friendly-snippets",
    module = { "cmp", "cmp_nvim_lsp" },
    event = "InsertEnter",
  }
  use { "hrsh7th/nvim-cmp",
    after = "friendly-snippets",
    config = function()
      require "core.plugins.cmp"
    end,
  }
  use { "L3MON4D3/LuaSnip",
    wants = "friendly-snippets",
    after = "nvim-cmp",
    config = function()
      require("core.plugins.configs").luasnip()
    end,
  }
  use { "saadparwaiz1/cmp_luasnip",
    after = "LuaSnip",
  }
  use { "hrsh7th/cmp-nvim-lua",
    after = "cmp_luasnip",
  }
  use { "hrsh7th/cmp-nvim-lsp",
    after = "cmp-nvim-lua",
  }
  use { "hrsh7th/cmp-buffer",
    after = "cmp-nvim-lsp",
  }
  use { "hrsh7th/cmp-path",
    after = "cmp-buffer",
  }

  -- misc plugins
  use { "windwp/nvim-autopairs",
    after = "nvim-cmp",
    config = function()
      require("core.plugins.configs").autopairs()
    end,
  }
  use { "goolord/alpha-nvim",
    config = function()
      require "core.plugins.alpha"
    end,
  }
  use { "numToStr/Comment.nvim",
    module = "Comment",
    keys = { "gc", "gb" },
    config = function()
      require("core.plugins.configs").comment()
    end,
    setup = function()
      require("core.utils").load_mappings "comment"
    end,
  }
  --
  -- file managing , picker etc
  use { "kyazdani42/nvim-tree.lua",
    ft = "alpha",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    config = function()
      require "core.plugins.nvimtree"
    end,
    setup = function()
      require("core.utils").load_mappings "nvimtree"
    end,
  }
  use { "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    config = function()
      require "core.plugins.telescope"
    end,
    setup = function()
      require("core.utils").load_mappings "telescope"
    end,
  }
  use { "nvim-telescope/telescope-fzf-native.nvim",
    run = "make"
  }

  -- Only load whichkey after all the gui
  use { "folke/which-key.nvim",
    module = "which-key",
    keys = "<leader>",
    config = function()
      require "core.plugins.whichkey"
    end,
    setup = function()
      require("core.utils").load_mappings "whichkey"
    end,
  }

  -- Speed up deffered plugins
  use { "lewis6991/impatient.nvim" }

  -- theme related
  use { "jwbaldwin/moonlight-material.vim" }
  use { "jwbaldwin/tokyonight.nvim",
    config = function()
      require("core.plugins.tokyonight")
    end
  }
  -- use { "catppuccin/nvim",
  --   as = "catppuccin",
  --   config = function()
  --     require("core.plugins.catppuccin")
  --   end
  -- }

  -- utility
  use { "ThePrimeagen/harpoon",
    config = function()
      require("core.plugins.configs").harpoon()
    end,
  }
  use { "tpope/vim-surround" }
  use { "tpope/vim-projectionist" }
  use { "vim-test/vim-test" }
  use { "rcarriga/nvim-notify" }
  use { "nvim-neotest/neotest-vim-test" }
  use { "jfpedroza/neotest-elixir" }
  use { "antoinemadec/FixCursorHold.nvim" }
  use { "nvim-neotest/neotest",
    config = function()
      require("core.plugins.neotest")
    end
  }
  use { "nvim-neorg/neorg",
    after = "nvim-treesitter",
    config = function()
      require("core.plugins.neorg")
    end
  }
  use { "ahmedkhalf/project.nvim",
    config = function()
      require("core.plugins.projects")
    end
  }
  use { "numToStr/FTerm.nvim",
    config = function()
      require("core.plugins.fterm")
    end
  }
  use { "ggandor/leap.nvim",
    config = function()
      require("core.plugins.leap")
    end
  }
  use { "olimorris/persisted.nvim",
    config = function()
      require("core.plugins.configs").persisted()
    end
  }

  -- ui plugins
  use { "nvim-lualine/lualine.nvim",
    config = function()
      require("core.plugins.lualine")
    end
  }
  use { "folke/todo-comments.nvim",
    config = function()
      require("core.plugins.configs").todo()
    end
  }


  -- Automatically set configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
