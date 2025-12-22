local M = {}

M.opts = {
	debug = {
		enabled = false,
		show_scores = true,
	},
	keymaps = {
		close = "<Esc>",
		select = "<CR>",
		select_split = "<C-s>",
		select_vsplit = "<C-v>",
		select_tab = "<C-t>",
		move_up = { "<Up>", "<C-p>", "<C-k>" },
		move_down = { "<Down>", "<C-n>", "<C-j>" },
		preview_scroll_up = "<C-u>",
		preview_scroll_down = "<C-d>",
		toggle_debug = "<F2>",
	},
}

M.keys = {
	{
		"ff",
		function()
			require("fff").find_files()
		end,
		desc = "FFFind files",
	},
}

M.build = function()
	require("fff.download").download_or_build_binary()
end

return M
