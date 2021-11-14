--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "material"
vim.opt.cmdheight = 1

-- Extra material.vim customizations
vim.g.material_terminal_italics = 1
vim.g.material_theme_style = "moonlight"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"

-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-q>"] = "<cmd> lua require('toggle_qf').toggle_qf()<cr>"  -- Toggle nvim-bqf quickfix list

-- Spectre keybindings
lvim.keys.normal_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.keys.visual_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.keys.visual_block_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"

-- Telescope configuration
lvim.builtin.telescope.defaults.prompt_prefix = '❯ '
lvim.builtin.telescope.defaults.file_ignore_patterns = {'node_modules/*', 'deps/*', 'build/*', '_build/*'}

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
lvim.builtin.telescope.on_config_done = function()
  require('telescope').load_extension('fzf')

  local actions = require "telescope.actions"
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
lvim.builtin.lualine.options.theme = "nightfly"

-- Use which-key to add extra bindings with the leader-key prefix
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
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
}

lvim.builtin.which_key.mappings.s.B = { "<cmd>Telescope file_browser<cr>", "File browser"}

lvim.builtin.which_key.mappings["r"] = {
  name = "+Spectre",
  r = {"<cmd>lua require('spectre').open()<cr>", "Open spectre - search and replace"},
  w = {"<cmd>lua require('spectre').open_visual({select_word=true})<cr>", "Open spectre on word"},
  f = {"<cmd>lua require('spectre').open_file_search()<cr>", "Open spectre for file"},
}

-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.side = "left"

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = "maintained"
lvim.builtin.treesitter.ignore_install = { "haskell" }
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
    {"shaunsingh/moonlight.nvim"},
    {"folke/tokyonight.nvim"},

    -- Language stuff
    {
      "folke/trouble.nvim",
      cmd = "TroubleToggle",
    },
    {"elixir-editors/vim-elixir"},

    -- Editor stuff
    {"tpope/vim-surround"},
    {"tpope/vim-projectionist"},
    {"vim-test/vim-test"},
    {"ggandor/lightspeed.nvim"},
    {"windwp/nvim-spectre"},
    -- {"github/copilot.vim"},
}


-- Plugin configuration
lvim.lsp.diagnostics.virtual_text = true
require('cmp').setup {
  completion = {
    completeopt = 'menu,menuone,noinsert',
  }
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

require('lightspeed').setup {
  jump_to_first_match = true,
  grey_out_search_area = true,
}

require('spectre').setup {
  is_insert_mode = true
}

-- Autocommands (https://neovim.io/doc/user/autocmd.html)
lvim.autocommands.custom_groups = {
  -- { "BufRead,BufNewFile", "*.html.*", "setf html" },
}
