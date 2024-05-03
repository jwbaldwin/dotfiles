local telescope = require("telescope")
local lga_status_ok, lga_actions = pcall(require, "telescope-live-grep-args.actions")
if not lga_status_ok then
	return
end

local options = {
	defaults = {
		vimgrep_arguments = {
			"rg",
			"--color=never",
			"--no-heading",
			"--with-filename",
			"--line-number",
			"--column",
			"--smart-case",
		},
		prompt_prefix = "   ",
		selection_caret = "❯ ",
		entry_prefix = "  ",
		initial_mode = "insert",
		selection_strategy = "reset",
		sorting_strategy = "ascending",
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
				prompt_position = "top",
				preview_width = 0.55,
				results_width = 0.8,
			},
			vertical = {
				mirror = false,
			},
			width = 0.87,
			height = 0.80,
			preview_cutoff = 120,
		},
		file_sorter = require("telescope.sorters").get_fuzzy_file,
		file_ignore_patterns = { "node_modules", "node_modules/*" },
		generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
		path_display = { "truncate" },
		winblend = 0,
		border = {},
		borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
		color_devicons = true,
		set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
		file_previewer = require("telescope.previewers").vim_buffer_cat.new,
		grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
		qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
		-- Developer configurations: Not meant for general override
		buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
		pickers = {
			find_files = {
				theme = "ivy",
				hidden = true,
			},
			live_grep = {
				--@usage don't include the filename in the search results
				only_sort_text = true,
			},
			projects = {
				theme = "ivy",
			},
		},
		mappings = {
			n = {
				["q"] = require("telescope.actions").close,
				["<C-j>"] = require("telescope.actions").move_selection_next,
				["<C-k>"] = require("telescope.actions").move_selection_previous,
				["<C-q>"] = require("telescope.actions").smart_send_to_qflist
					+ require("telescope.actions").open_qflist,
			},
			i = {
				["<C-j>"] = require("telescope.actions").move_selection_next,
				["<C-k>"] = require("telescope.actions").move_selection_previous,
				["<C-c>"] = require("telescope.actions").close,
				["<C-n>"] = require("telescope.actions").cycle_history_next,
				["<C-p>"] = require("telescope.actions").cycle_history_prev,
				["<C-q>"] = require("telescope.actions").smart_send_to_qflist
					+ require("telescope.actions").open_qflist,
				["<CR>"] = require("telescope.actions").select_default,
				["<Esc>"] = require("telescope.actions").close,
			},
		},
	},
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
		smart_open = {
			show_scores = false,
			ignore_patterns = { "*.git/*", "*/tmp/*" },
			match_algorithm = "fzf",
			disable_devicons = false,
		},
		live_grep_args = {
			only_sort_text = true,
			mappings = {
				i = {
					["<C-f>"] = lga_actions.quote_prompt(),
					["<C-g>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
				},
			},
		},
	},
}

telescope.setup(options)

telescope.load_extension("fzf")
telescope.load_extension("live_grep_args")
telescope.load_extension("projects")
telescope.load_extension("enhanced_find_files")
