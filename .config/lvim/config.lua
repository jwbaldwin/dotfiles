-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "duskfox"
-- lvim.colorscheme = "material"
vim.opt.cmdheight = 1
vim.opt.timeoutlen = 200

-- Extra material.vim customizations
vim.g.material_terminal_italics = 1
vim.g.material_theme_style = "moonlight"
vim.g.ayucolor="mirage"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"

-- add your own keymapping
lvim.keys.normal_mode["<C-y>"] = ":w<cr>"
lvim.keys.normal_mode["<S-Up>"] = ":move-2<cr>"
lvim.keys.normal_mode["<S-Down>"] = ":move+<cr>"
lvim.keys.normal_mode["wh"] = ":wincmd h<cr>"
lvim.keys.normal_mode["wj"] = ":wincmd j<cr>"
lvim.keys.normal_mode["wk"] = ":wincmd k<cr>"
lvim.keys.normal_mode["wl"] = ":wincmd l<cr>"

-- Harpoon keybindings
lvim.keys.normal_mode["<C-h>"] = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>"
lvim.keys.normal_mode["<C-e>"] = "<cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>"

lvim.keys.normal_mode["<C-j>"] = "<cmd>lua require('harpoon.ui').nav_file(1)<cr>"
lvim.keys.normal_mode["<C-k>"] = "<cmd>lua require('harpoon.ui').nav_file(2)<cr>"
lvim.keys.normal_mode["<C-l>"] = "<cmd>lua require('harpoon.ui').nav_file(3)<cr>"
lvim.keys.normal_mode["<C-;>"] = "<cmd>lua require('harpoon.ui').nav_file(4)<cr>"

-- Spectre keybindings
lvim.keys.normal_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.keys.visual_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.keys.visual_block_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"

-- Telescope configuration
lvim.builtin.telescope.defaults.prompt_prefix = '❯ '
lvim.builtin.telescope.defaults.selection_caret = '> '
lvim.builtin.telescope.defaults.file_ignore_patterns = {'node_modules/*', 'deps/*', 'build/*', '_build/*'}
lvim.builtin.telescope.defaults.path_display.shorten = 8

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- #TODO: add item for searching and editing dotfiles
lvim.builtin.telescope.on_config_done = function()
  require('telescope').load_extension('fzf')

  require('telescope').setup {
    defaults = {
      preview = {
        treesitter = false
      }
    },
    pickers = {
      find_files = { theme = "dropdown", disable_devicons = true, previewer = false},
      git_files = { theme = "dropdown", disable_devicons = true, previewer = false},
      projects = { theme = "dropdown", disable_devicons = true, previewer = false}
    }
  }

  local actions = require "telescope.actions"
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

-- Customize lualine
local components = require("lvim.core.lualine.components")

lvim.builtin.lualine = {
  active = true,
  style = "default",
  options = {
    icons_enabled = true,
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
    disabled_filetypes = {"alpha", "NvimTree", "Outline"},
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

-- Use which-key to add extra bindings with the leader-key prefix
-- -- Bufferline
-- lvim.builtin.which_key.mappings["b"]["l"] = { "<cmd>BufferMoveNext<cr>", "Move right" }
-- lvim.builtin.which_key.mappings["b"]["h"] = { "<cmd>BufferMovePrevious<cr>", "Move left" }
-- lvim.builtin.which_key.mappings["b"]["L"] = { "<cmd>BufferCloseBuffersRight<cr>", "Close all to the right" }
-- lvim.builtin.which_key.mappings["b"]["H"] = { "<cmd>BufferCloseBuffersLeft<cr>", "Close all to the left" }
-- lvim.builtin.which_key.mappings["b"]["p"] = { "<cmd>BufferPin<cr>", "Pin" }

lvim.builtin.which_key.mappings["g"]["a"] = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" }
lvim.builtin.which_key.mappings["g"]["s"] = { "<cmd>Telescope git_status<cr>", "Open changed file" }
lvim.builtin.which_key.mappings["p"] = { "<cmd>Telescope projects<CR>", "Projects" }
lvim.builtin.which_key.mappings["P"] = {
  name = "Packer",
  c = { "<cmd>PackerCompile<cr>", "Compile" },
  i = { "<cmd>PackerInstall<cr>", "Install" },
  r = { "<cmd>lua require('lvim.plugin-loader').recompile()<cr>", "Re-compile" },
  s = { "<cmd>PackerSync<cr>", "Sync" },
  S = { "<cmd>PackerStatus<cr>", "Status" },
  u = { "<cmd>PackerUpdate<cr>", "Update" },
}
lvim.builtin.which_key.mappings["t"] = {
  name = "+Trouble",
  r = { "<cmd>Trouble lsp_references<cr>", "References" },
  f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
  d = { "<cmd>Trouble lsp_document_diagnostics<cr>", "Diagnostics" },
  q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
  l = { "<cmd>Trouble loclist<cr>", "LocationList" },
  w = { "<cmd>Trouble lsp_workspace_diagnostics<cr>", "Diagnostics" },
}
lvim.builtin.which_key.mappings["x"] = {
  name = "+vim-test",
  n = {"<cmd>TestNearest<cr>", "Test nearest"},
  f = {"<cmd>TestFile<cr>", "Test file"},
  s = {"<cmd>TestSuite<cr>", "Test suite"},
  l = {"<cmd>TestLast<cr>", "Test last"},
  g = {"<cmd>TestVisit<cr>", "Test visit"},
  c = {"<cmd>!mix credo --strict<cr>", "Run credo strict"},
  m = {"<cmd>!mix test<cr>", "Mix test"},
  F = {"<cmd>!mix test --failed<cr>", "Mix test [failed]"},
}

lvim.builtin.which_key.mappings.s.B = { "<cmd>Telescope file_browser<cr>", "File browser"}

lvim.builtin.which_key.mappings["r"] = {
  name = "+Spectre",
  r = {"<cmd>lua require('spectre').open()<cr>", "Open spectre - search and replace"},
  w = {"<cmd>lua require('spectre').open_visual({select_word=true})<cr>", "Open spectre on word"},
  f = {"<cmd>lua require('spectre').open_file_search()<cr>", "Open spectre for file"},
}

lvim.builtin.which_key.mappings["a"] = {"<cmd>lua require('harpoon.mark').add_file()<cr>", "Throw harpoon"}
lvim.builtin.which_key.mappings["h"] = {
  name = "Harpoon",
  a = {"<cmd>lua require('harpoon.mark').add_file()<cr>", "Mark"},
  ["j"] = {"<cmd>lua require('harpoon.ui').nav_file(1)<cr>", "first"},
  ["k"] = {"<cmd>lua require('harpoon.ui').nav_file(2)<cr>", "second"},
  ["l"] = {"<cmd>lua require('harpoon.ui').nav_file(3)<cr>", "third"},
  [";"] = {"<cmd>lua require('harpoon.ui').nav_file(4)<cr>", "fourth"},
}

-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.side = "left"

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = "maintained"
lvim.builtin.treesitter.highlight.enabled = true

-- generic LSP settings
-- you can set a custom on_attach function that will be used for all the language servers
-- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end
-- you can overwrite the null_ls setup table (useful for setting the root_dir function)
-- lvim.lsp.null_ls.setup = {
--   root_dir = require("lspconfig").util.root_pattern("Makefile", ".git", "node_modules"),
-- }
-- or if you need something more advanced
-- lvim.lsp.null_ls.setup.root_dir = function(fname)
--   if vim.bo.filetype == "javascript" then
--     return require("lspconfig/util").root_pattern("Makefile", ".git", "node_modules")(fname)
--       or require("lspconfig/util").path.dirname(fname)
--   elseif vim.bo.filetype == "php" then
--     return require("lspconfig/util").root_pattern("Makefile", ".git", "composer.json")(fname) or vim.fn.getcwd()
--   else
--     return require("lspconfig/util").root_pattern("Makefile", ".git")(fname) or require("lspconfig/util").path.dirname(fname)
--   end
-- end

-- set a formatter if you want to override the default lsp one (if it exists)
-- lvim.lang.python.formatters = {
--   {
--     exe = "black",
--   }
-- }
-- set an additional linter
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   {
--     exe = "credo",
--     filetypes = { "elixir" }
--   }
-- }

-- Additional Plugins
lvim.plugins = {
    -- Themes
    {"jwbaldwin/moonlight-material.vim"},
    -- {"~/repos/moonlight-material.vim"},
    {"nvim-treesitter/playground"},
    {"shaunsingh/moonlight.nvim"},
    {"ayu-theme/ayu-vim"},
    {"folke/tokyonight.nvim"},
    {"EdenEast/nightfox.nvim"},

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
    -- {"elixir-editors/vim-elixir"},

    -- Editor stuff
    {"tpope/vim-surround"},
    {"tpope/vim-projectionist"},
    {"dkuku/vim-projectionist-elixir"},
    {"c-brenn/fuzzy-projectionist.vim"},
    {"vim-test/vim-test"},
    {"ggandor/lightspeed.nvim"},
    -- {"phaazon/hop.nvim",
    --   branch = 'v1',
    --   config = function()
    --     -- you can configure Hop the way you like here; see :h hop-config
    --     require'hop'.setup()
    --   end
    -- },
    {"windwp/nvim-spectre"},
    {"kevinhwang91/nvim-bqf", ft = 'qf'},
    {"ThePrimeagen/harpoon"}
    -- {"github/copilot.vim"},
}


-- Plugin configuration
lvim.lsp.diagnostics.virtual_text = true

require("cmp").setup ({
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
})

-- Hop configuration
-- vim.api.nvim_set_keymap('n', 's', "<cmd>lua require'hop'.hint_words()<cr>", {})
-- vim.api.nvim_set_keymap('n', 'S', "<cmd>lua require'hop'.hint_lines()<cr>", {})

require("lightspeed").setup {
  ignore_case = true
}

-- Makes copilot and C-e complete work with cmp
-- vim.g.copilot_no_tab_map = true
-- vim.g.copilot_assume_mapped = true
-- vim.g.copilot_tab_fallback = ""
-- local cmp = require "cmp"
-- lvim.builtin.cmp.mapping["<C-e>"] = function(fallback)
--   cmp.mapping.abort()
--   local copilot_keys = vim.fn["copilot#Accept"]()
--   if copilot_keys ~= "" then
--     vim.api.nvim_feedkeys(copilot_keys, "i", true)
--   else
--     fallback()
--   end
-- end


-- vim-test and vim-projectionist
vim.g['test#strategy'] = 'neovim'
vim.g['test#neovim#term_position'] = 'vertical'
vim.g['test#echo_command'] = 1
vim.g['test#start_normal'] = 1

require('spectre').setup {
  is_insert_mode = false
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- lvim.autocommands.custom_groups = {
  -- { "BufRead,BufNewFile", "*.html.*", "setf html" },
-- }

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

lvim.keys.normal_mode["<C-q>"] = "<cmd> lua Toggle_qf()<cr>"  -- Toggle nvim-bqf quickfix list

---
-- Load in my stuff
---
lvim.builtin.alpha.mode = "custom"
local alpha_opts = require("user.dashboard").config()
lvim.builtin.alpha["custom"] = { config = alpha_opts }
