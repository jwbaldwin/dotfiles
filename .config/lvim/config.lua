-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "material"
lvim.use_icons = true

-- Extra material.vim customizations
vim.g.material_terminal_italics = 1
vim.g.material_theme_style = "moonlight"
vim.g.ayucolor = "mirage"

vim.opt.cmdheight = 1
vim.opt.timeoutlen = 200

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}

lvim.builtin.treesitter.highlight.enabled = true

-- generic LSP settings
lvim.lsp.installer.setup.ensure_installed = {
  "elixirls",
  "sumeko_lua",
  "jsonls",
}

-- ---@usage disable automatic installation of servers
lvim.lsp.installer.setup.automatic_installation = false

-- Telescope configuration
lvim.builtin.telescope.defaults.prompt_prefix = '❯ '
lvim.builtin.telescope.defaults.selection_caret = '> '
lvim.builtin.telescope.defaults.file_ignore_patterns = { 'node_modules/*', 'deps/*', 'build/*', '_build/*' }
lvim.builtin.telescope.defaults.path_display.shorten = 12

-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.treesitter.highlight.enabled = true

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- #TODO: add item for searching and editing dotfiles
lvim.builtin.telescope.on_config_done = function()
  require("telescope").load_extension "enhanced_find_files"
  --   require('telescope').setup {
  --     defaults = {
  --       preview = {
  --         treesitter = false
  --       }
  --     },
  --     pickers = {
  --       --   find_files = { theme = "dropdown", disable_devicons = true, previewer = false },
  --       --   git_files = { theme = "dropdown", disable_devicons = true, previewer = false },
  --       projects = { theme = "dropdown", disable_devicons = true, previewer = false }
  --     }
  --   }

  local actions = require("telescope.actions")
  require("telescope").setup {
    pickers = {
      buffers = {
        sort_lastused = true
      }
    }
  }

  lvim.builtin.telescope.defaults.mappings.i["<C-p>"] = actions.cycle_history_prev

  -- for input mode
  lvim.builtin.telescope.defaults.mappings.i["<C-j>"] = actions.move_selection_next
  lvim.builtin.telescope.defaults.mappings.i["<C-k>"] = actions.move_selection_previous
  lvim.builtin.telescope.defaults.mappings.i["<C-n>"] = actions.cycle_history_next
  lvim.builtin.telescope.defaults.mappings.i["<C-p>"] = actions.cycle_history_prev

  -- for normal mode
  lvim.builtin.telescope.defaults.mappings.n["<C-j>"] = actions.move_selection_next
  lvim.builtin.telescope.defaults.mappings.n["<C-k>"] = actions.move_selection_previous
end

-- Additional Plugins
lvim.plugins = {
  -- Themes
  { "jwbaldwin/moonlight-material.vim" },
  { "shaunsingh/moonlight.nvim" },
  { "ayu-theme/ayu-vim" },
  { "folke/tokyonight.nvim" },
  { "EdenEast/nightfox.nvim" },

  -- Language and Sessions stuff
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    module = "persistence",
    config = function()
      require("persistence").setup()
    end,
  },

  -- Editor stuff
  { "tpope/vim-surround" },
  { "tpope/vim-projectionist" },
  { "dkuku/vim-projectionist-elixir" },
  { "c-brenn/fuzzy-projectionist.vim" },
  { "vim-test/vim-test" },
  { "ggandor/lightspeed.nvim" },
  { "windwp/nvim-spectre" },
  { "kevinhwang91/nvim-bqf", ft = 'qf' },
  { "ThePrimeagen/harpoon" },
  -- {
  --   "nvim-telescope/telescope-fzf-native.nvim",
  --   run = "make",
  --   after = "telescope.nvim",
  --   config = function()
  --     require("telescope").load_extension "fzf"
  --   end,
  -- }
}


-- Plugin configuration
lvim.lsp.diagnostics.virtual_text = true

require("cmp").setup({
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
})

-- Customize lualine
local components = require("lvim.core.lualine.components")

lvim.builtin.lualine = {
  active = true,
  style = "default",
  options = {
    icons_enabled = true,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = { "alpha", "NvimTree", "Outline" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { components.branch, { "filename", path = 1, shorting_target = 20 } },
    lualine_c = { components.diff, components.python_env },
    lualine_x = {
      components.diagnostics,
      components.treesitter,
      components.lsp,
      components.filetype,
    },
    lualine_y = { "location" },
    lualine_z = { "progress" },
  },
  inactive_sections = {
    lualine_a = { "filename" },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
  tabline = {},
  extensions = { "nvim-tree" },
}

---------------------------------------
--------- Extra Plugin Config ---------
---------------------------------------
-- Hop configuration
-- vim.api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_words()<cr>", {})
-- vim.api.nvim_set_keymap('n', 'S', "<cmd>lua require'hop'.hint_lines()<cr>", {})
require("lightspeed").setup {
  ignore_case = true
}

vim.g['test#strategy'] = 'neovim'
vim.g['test#neovim#term_position'] = 'vertical'
vim.g['test#echo_command'] = 1
vim.g['test#start_normal'] = 1

require('spectre').setup {
  is_insert_mode = false
}



-- Autocommands (https://neovim.io/doc/user/autocmd.html)

-- Toggle quickfix
Toggle_qf = function()
  local qf_open = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_open = true
    end
  end
  if qf_open == true then
    vim.cmd("cclose")
    return
  end
  if not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd("copen")
  end
end


vim.api.nvim_create_autocmd("FileType", {
  pattern = "zsh",
  callback = function()
    -- let treesitter use bash highlight for zsh files as well
    require("nvim-treesitter.highlight").attach(0, "bash")
  end,
})


---
-- Load in my stuff
---
require("f/keymap")

lvim.builtin.alpha.mode = "custom"
local alpha_opts = require("user.dashboard").config()
lvim.builtin.alpha["custom"] = { config = alpha_opts }
