lvim.leader = "space"

lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<Space>bp"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<Space>bl"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<Space>bk"] = ":BufferKill<CR>"
lvim.keys.normal_mode["<Space>."] = ":Telescope enhanced_find_files<CR>"
lvim.keys.normal_mode["<Space>,"] = ":Telescope buffers<CR>"
lvim.keys.normal_mode["<Space>pp"] = ":Telescope buffers<CR>"
lvim.keys.normal_mode["<Space>/"] = ":Telescope live_grep<CR>"
lvim.keys.normal_mode["<M>/"] = "<Plug>(comment_toggle_linewise_visual)"
-- ["/"] = { "<Plug>(comment_toggle_linewise_visual)", "Comment toggle linewise (visual)" },

lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-y>"] = ":w<cr>"
lvim.keys.normal_mode["<S-Up>"] = ":move-2<cr>"
lvim.keys.normal_mode["<S-Down>"] = ":move+<cr>"
lvim.keys.normal_mode["<Space>wh"] = ":wincmd h<cr>"
lvim.keys.normal_mode["<Space>wj"] = ":wincmd j<cr>"
lvim.keys.normal_mode["<Space>wk"] = ":wincmd k<cr>"
lvim.keys.normal_mode["<Space>wl"] = ":wincmd l<cr>"

-- Projects
lvim.builtin.which_key.mappings["p"] = {
  name = "Projects",
  ["p"] = { ":Telescope projects<CR>", "Projects" },
}

-- Harpoon keybindings
lvim.keys.normal_mode["<C-h>"] = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>"
lvim.keys.normal_mode["<C-e>"] = "<cmd>lua require('harpoon.cmd-ui').toggle_quick_menu()<cr>"

lvim.keys.normal_mode["<C-j>"] = "<cmd>lua require('harpoon.ui').nav_file(1)<cr>"
lvim.keys.normal_mode["<C-k>"] = "<cmd>lua require('harpoon.ui').nav_file(2)<cr>"
lvim.keys.normal_mode["<C-l>"] = "<cmd>lua require('harpoon.ui').nav_file(3)<cr>"
lvim.keys.normal_mode["<C-;>"] = "<cmd>lua require('harpoon.ui').nav_file(4)<cr>"
lvim.keys.normal_mode["<C-f>"] = "<cmd>lua require('harpoon.mark').add_file()<cr>"
lvim.builtin.which_key.mappings["h"] = {
  name = "Harpoon",
  ["f"] = { "<cmd>lua require('harpoon.mark').add_file()<cr>", "Mark" },
  ["j"] = { "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", "first" },
  ["k"] = { "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", "second" },
  ["l"] = { "<cmd>lua require('harpoon.ui').nav_file(3)<cr>", "third" },
  [";"] = { "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", "fourth" },
}

-- Spectre keybindings
lvim.keys.normal_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.keys.visual_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.keys.visual_block_mode["<C-p>"] = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>"
lvim.builtin.which_key.mappings["r"] = {
  name = "+Spectre",
  r = { "<cmd>lua require('spectre').open()<cr>", "Open spectre - search and replace" },
  w = { "<cmd>lua require('spectre').open_visual({select_word=true})<cr>", "Open spectre on word" },
  f = { "<cmd>lua require('spectre').open_file_search()<cr>", "Open spectre for file" },
}

-- Elixir test keybindings
lvim.builtin.which_key.mappings["t"] = {
  name = "+test",
  n = { "<cmd>TestNearest<cr>", "Test nearest" },
  f = { "<cmd>TestFile<cr>", "Test file" },
  s = { "<cmd>TestSuite<cr>", "Test suite" },
  l = { "<cmd>TestLast<cr>", "Test last" },
  g = { "<cmd>TestVisit<cr>", "Test visit" },
  c = { "<cmd>!mix credo --strict<cr>", "Run credo strict" },
  m = { "<cmd>!mix test<cr>", "Mix test" },
  F = { "<cmd>!mix test --failed<cr>", "Mix test [failed]" },
}

lvim.keys.normal_mode["<C-q>"] = "<cmd> lua Toggle_qf()<cr>" -- Toggle nvim-bqf quickfix list
