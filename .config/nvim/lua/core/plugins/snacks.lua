return {
	opts = {
		bigfile = { enabled = true },
		git = { enabled = true },
		gitbrowse = { enabled = true },
		explorer = { enabled = true },
		input = { enabled = true },
		quickfile = { enabled = true },
		rename = { enabled = true },
		scope = { enabled = true },
		scratch = { enabled = true },
		statuscolumn = { enabled = true },
		toggle = { enabled = true },
		words = { enabled = true },

		-- Dashboard Configuration
		dashboard = {
			formats = {
				key = function(item)
					return {
						{ "[", hl = "special" },
						{ item.key, hl = "key" },
						{ "]", hl = "special" },
					}
				end,
			},
			sections = {
				{
					section = "terminal",
					cmd = "chafa ~/.config/nvim/lua/core/plugins/images/cabin.jpg --format symbols --symbols vhalf --size 60x15 --stretch; sleep .1",
					height = 15,
					padding = 2,
				},
				{ title = "mru", padding = 1 },
				{ section = "recent_files", limit = 5, padding = 1 },
				{ title = "", file = vim.fn.fnamemodify(".", ":~"), padding = 1 },
				{ section = "recent_files", cwd = true, limit = 5, padding = 1 },
				{ icon = "/", title = "Projects", section = "projects", padding = 2 },
				{ key = "q", action = ":qa" },
			},
		},

		-- Notifier Configuration
		notifier = {
			enabled = true,
			timeout = 3000,
		},

		-- Picker Configuration
		picker = {
			prompt = " ",
			sources = {},
			focus = "input",

			-- Picker - Layout
			layout = {
				cycle = true,
				preset = function()
					return vim.o.columns >= 120 and "default" or "vertical"
				end,
			},

			-- Picker - Matcher Configuration
			matcher = {
				fuzzy = true,
				smartcase = true,
				ignorecase = true,
				sort_empty = false,
				filename_bonus = true,
				file_pos = true,
				cwd_bonus = true,
				frecency = true,
				history_bonus = true,
			},

			-- Picker - Sort Configuration
			sort = {
				fields = { "score:desc", "#text", "idx" },
			},

			ui_select = true,

			-- Picker - Formatters
			formatters = {
				text = {
					ft = nil,
				},
				file = {
					filename_first = false,
					truncate = 60,
					filename_only = false,
					icon_width = 2,
				},
				selected = {
					show_always = false,
					unselected = true,
				},
				severity = {
					icons = true,
					level = false,
					pos = "left",
				},
			},

			-- Picker - Previewers
			previewers = {
				git = {
					native = false,
				},
				file = {
					max_size = 1024 * 1024, -- 1MB
					max_line_length = 500,
					ft = nil,
				},
				man_pager = nil,
			},

			-- Picker - Jump Configuration
			jump = {
				jumplist = true,
				tagstack = false,
				reuse_win = false,
				close = true,
				match = false,
			},

			-- Picker - Toggles
			toggles = {
				follow = "f",
				hidden = "h",
				ignored = "i",
				modified = "m",
				regex = { icon = "R", value = false },
			},

			-- Picker - Window Configuration
			win = {
				input = {
					keys = {
						["<Esc>"] = { "close", mode = { "n", "i" } },
						["/"] = "toggle_focus",
						["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
						["<C-Up>"] = { "history_back", mode = { "i", "n" } },
						["<C-c>"] = { "close", mode = "i" },
						["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
						["<CR>"] = { "confirm", mode = { "n", "i" } },
						["<Down>"] = { "list_down", mode = { "i", "n" } },
						["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
						["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
						["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
						["<Up>"] = { "list_up", mode = { "i", "n" } },
						["<a-d>"] = { "inspect", mode = { "n", "i" } },
						["<a-f>"] = { "toggle_follow", mode = { "i", "n" } },
						["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
						["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
						["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
						["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
						["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
						["<c-a>"] = { "select_all", mode = { "n", "i" } },
						["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
						["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
						["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
						["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
						["<c-j>"] = { "list_down", mode = { "i", "n" } },
						["<c-k>"] = { "list_up", mode = { "i", "n" } },
						["<c-n>"] = { "history_forward", mode = { "i", "n" } },
						["<c-p>"] = { "history_back", mode = { "i", "n" } },
						["<c-q>"] = { "qflist", mode = { "i", "n" } },
						["<c-s>"] = { "edit_split", mode = { "i", "n" } },
						["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
						["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
						["<c-z>h"] = { "layout_left", mode = { "i", "n" } },
						["<c-z><c-h>"] = { "layout_left", mode = { "i", "n" } },
						["<c-z>j"] = { "layout_bottom", mode = { "i", "n" } },
						["<c-z><c-j>"] = { "layout_bottom", mode = { "i", "n" } },
						["<c-z>k"] = { "layout_top", mode = { "i", "n" } },
						["<c-z><c-k>"] = { "layout_top", mode = { "i", "n" } },
						["<c-z>l"] = { "layout_right", mode = { "i", "n" } },
						["<c-z><c-l>"] = { "layout_right", mode = { "i", "n" } },
						["?"] = "toggle_help_input",
						["G"] = "list_bottom",
						["gg"] = "list_top",
						["j"] = "list_down",
						["k"] = "list_up",
						["q"] = "close",
					},
					b = {
						minipairs_disable = true,
					},
				},
				list = {
					keys = {
						["/"] = "toggle_focus",
						["<2-LeftMouse>"] = "confirm",
						["<CR>"] = "confirm",
						["<Down>"] = "list_down",
						["<Esc>"] = "close",
						["<S-CR>"] = { { "pick_win", "jump" } },
						["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },
						["<Tab>"] = { "select_and_next", mode = { "n", "x" } },
						["<Up>"] = "list_up",
						["<a-d>"] = "inspect",
						["<a-f>"] = "toggle_follow",
						["<a-h>"] = "toggle_hidden",
						["<a-i>"] = "toggle_ignored",
						["<a-m>"] = "toggle_maximize",
						["<a-p>"] = "toggle_preview",
						["<a-w>"] = "cycle_win",
						["<c-a>"] = "select_all",
						["<c-b>"] = "preview_scroll_up",
						["<c-d>"] = "list_scroll_down",
						["<c-f>"] = "preview_scroll_down",
						["<c-j>"] = "list_down",
						["<c-k>"] = "list_up",
						["<c-n>"] = "history_forward",
						["<c-p>"] = "history_back",
						["<c-s>"] = "edit_split",
						["<c-u>"] = "list_scroll_up",
						["<c-v>"] = "edit_vsplit",
						["<c-z>h"] = { "layout_left", mode = { "i", "n" } },
						["<c-z><c-h>"] = { "layout_left", mode = { "i", "n" } },
						["<c-z>j"] = { "layout_bottom", mode = { "i", "n" } },
						["<c-z><c-j>"] = { "layout_bottom", mode = { "i", "n" } },
						["<c-z>k"] = { "layout_top", mode = { "i", "n" } },
						["<c-z><c-k>"] = { "layout_top", mode = { "i", "n" } },
						["<c-z>l"] = { "layout_right", mode = { "i", "n" } },
						["<c-z><c-l>"] = { "layout_right", mode = { "i", "n" } },
						["?"] = "toggle_help_list",
						["G"] = "list_bottom",
						["gg"] = "list_top",
						["i"] = "focus_input",
						["j"] = "list_down",
						["k"] = "list_up",
						["q"] = "close",
						["zb"] = "list_scroll_bottom",
						["zt"] = "list_scroll_top",
						["zz"] = "list_scroll_center",
					},
					wo = {
						conceallevel = 2,
						concealcursor = "nvc",
					},
				},
				preview = {
					keys = {
						["<Esc>"] = "close",
						["q"] = "close",
						["i"] = "focus_input",
						["<ScrollWheelDown>"] = "list_scroll_wheel_down",
						["<ScrollWheelUp>"] = "list_scroll_wheel_up",
						["<a-w>"] = "cycle_win",
					},
				},
			},

			-- Icons Configuration
			icons = {
				files = { enabled = true },
				keymaps = { nowait = "󰓅 " },
				tree = {
					vertical = "│ ",
					middle = "├╴",
					last = "└╴",
				},
				undo = { saved = " " },
				ui = {
					live = "󰐰 ",
					hidden = "h",
					ignored = "i",
					follow = "f",
					selected = "● ",
					unselected = "○ ",
				},
				git = {
					enabled = true,
					commit = "󰜘 ",
					staged = "●",
					added = "",
					deleted = "",
					ignored = " ",
					modified = "○",
					renamed = "",
					unmerged = " ",
					untracked = "?",
				},
				diagnostics = {
					Error = " ",
					Warn = " ",
					Hint = " ",
					Info = " ",
				},
				kinds = {
					Array = " ",
					Boolean = "󰨙 ",
					Class = " ",
					Color = " ",
					Control = " ",
					Collapsed = " ",
					Constant = "󰏿 ",
					Constructor = " ",
					Copilot = " ",
					Enum = " ",
					EnumMember = " ",
					Event = " ",
					Field = " ",
					File = " ",
					Folder = " ",
					Function = "󰊕 ",
					Interface = " ",
					Key = " ",
					Keyword = " ",
					Method = "󰊕 ",
					Module = " ",
					Namespace = "󰦮 ",
					Null = " ",
					Number = "󰎠 ",
					Object = " ",
					Operator = " ",
					Package = " ",
					Property = " ",
					Reference = " ",
					Snippet = "󱄽 ",
					String = " ",
					Struct = "󰆼 ",
					Text = " ",
					TypeParameter = " ",
					Unit = " ",
					Unknown = " ",
					Value = " ",
					Variable = "󰀫 ",
				},
			},

			-- Debug Configuration
			debug = {
				scores = false,
				leaks = false,
				explorer = false,
				files = false,
				grep = false,
				extmarks = false,
			},
		},

		-- Styles
		styles = {
			notification = {
				-- wo = { wrap = true } -- Wrap notifications
			},
		},
	},

	-- ============================================================================
	-- KEY MAPPINGS
	-- ============================================================================
	keys = {
		{
			"<leader>.",
			function()
				Snacks.picker.smart({
					multi = { "buffers", "recent", { source = "files", exclude = { "docs/**" } } },
					format = "file",
					matcher = {
						cwd_bonus = true,
						frecency = true,
						sort_empty = true,
					},
					transform = "unique_file",
				})
			end,
			desc = "Smart Find Files",
		},
		{
			"<leader>,",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>'",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>:",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>nh",
			function()
				Snacks.picker.notifications()
			end,
			desc = "[N]otification [h]istory",
		},
		{
			"<leader>e",
			function()
				Snacks.explorer()
			end,
			desc = "File [e]xplorer",
		},

		-- Find (f)
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "[F]ind [b]uffers",
		},
		{
			"<leader>fc",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "[F]ind [c]onfig File",
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "[F]ind [f]iles",
		},
		{
			"<leader>fg",
			function()
				Snacks.picker.git_files()
			end,
			desc = "[F]ind [g]it giles",
		},
		{
			"<leader>fp",
			function()
				Snacks.picker.projects()
			end,
			desc = "[F]ind [p]rojects",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.recent()
			end,
			desc = "[F]ind [r]ecent",
		},

		-- Git (g)
		{
			"<leader>gl",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "[G]it [l]ist branches",
		},
		{
			"<leader>gL",
			function()
				Snacks.picker.git_log_line()
			end,
			desc = "[G]it [L]og line",
		},
		{
			"<leader>gs",
			function()
				Snacks.picker.git_status()
			end,
			desc = "[G]it [s]tatus",
		},
		{
			"<leader>gS",
			function()
				Snacks.picker.git_stash()
			end,
			desc = "[G]it [S]tash",
		},
		{
			"<leader>gd",
			function()
				Snacks.picker.git_diff()
			end,
			desc = "[G]it [d]iff (Hunks)",
		},
		{
			"<leader>gf",
			function()
				Snacks.picker.git_log_file()
			end,
			desc = "[G]it log [f]ile",
		},
		{
			"<leader>gB",
			function()
				Snacks.git.blame_line()
			end,
			desc = "[G]it [b]lame line",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse()
			end,
			desc = "[G]it [B]rowse",
			mode = { "n", "v" },
		},
		{
			"<leader>gc",
			function()
				Snacks.git.commit()
			end,
		},

		-- Search (s)
		{
			"<leader>sb",
			function()
				Snacks.picker.lines()
			end,
			desc = "Buffer Lines",
		},
		{
			"<leader>sB",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Grep Open Buffers",
		},
		{
			"<leader>sg",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>sw",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Visual selection or word",
			mode = { "n", "x" },
		},
		{
			'<leader>s"',
			function()
				Snacks.picker.registers()
			end,
			desc = "Registers",
		},
		{
			"<leader>s/",
			function()
				Snacks.picker.search_history()
			end,
			desc = "Search History",
		},
		{
			"<leader>sa",
			function()
				Snacks.picker.autocmds()
			end,
			desc = "Autocmds",
		},
		{
			"<leader>sc",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>sC",
			function()
				Snacks.picker.commands()
			end,
			desc = "Commands",
		},
		{
			"<leader>sd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Diagnostics",
		},
		{
			"<leader>sD",
			function()
				Snacks.picker.diagnostics_buffer()
			end,
			desc = "Buffer Diagnostics",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Pages",
		},
		{
			"<leader>sH",
			function()
				Snacks.picker.highlights()
			end,
			desc = "Highlights",
		},
		{
			"<leader>sk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"<leader>sl",
			function()
				Snacks.picker.loclist()
			end,
			desc = "Location List",
		},
		{
			"<leader>sm",
			function()
				Snacks.picker.marks()
			end,
			desc = "Marks",
		},
		{
			"<leader>sM",
			function()
				Snacks.picker.man()
			end,
			desc = "Man Pages",
		},
		{
			"<leader>sp",
			function()
				Snacks.picker.lazy()
			end,
			desc = "Search for Plugin Spec",
		},
		{
			"<leader>sq",
			function()
				Snacks.picker.qflist()
			end,
			desc = "Quickfix List",
		},
		{
			"<leader>sR",
			function()
				Snacks.picker.resume()
			end,
			desc = "Resume",
		},
		{
			"<leader>su",
			function()
				Snacks.picker.undo()
			end,
			desc = "Undo History",
		},
		{
			"<leader>ss",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		{
			"<leader>sS",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "LSP Workspace Symbols",
		},

		-- LSP Navigation
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
		{
			"gD",
			function()
				Snacks.picker.lsp_declarations()
			end,
			desc = "Goto Declaration",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Goto Implementation",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Goto T[y]pe Definition",
		},

		-- UI Toggles (u)
		{
			"<leader>uC",
			function()
				Snacks.picker.colorschemes()
			end,
			desc = "Colorschemes",
		},
		{
			"<leader>nd",
			function()
				Snacks.notifier.hide()
			end,
			desc = "[D]ismiss all [n]otifications",
		},

		-- Buffer & Window Management
		{
			"<leader>z",
			function()
				Snacks.zen()
			end,
			desc = "Toggle Zen Mode",
		},
		{
			"<leader>Z",
			function()
				Snacks.zen.zoom()
			end,
			desc = "Toggle Zoom",
		},
		{
			"<leader>s",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<leader>bd",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},

		-- File Operations (c)
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},

		-- Navigation
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			desc = "Next Reference",
			mode = { "n", "t" },
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			desc = "Prev Reference",
			mode = { "n", "t" },
		},
	},

	-- ============================================================================
	-- INITIALIZATION
	-- ============================================================================
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Debug utilities
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd -- Override print to use snacks for `:=` command

				-- Toggle mappings
				Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
				Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
				Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
				Snacks.toggle.diagnostics():map("<leader>ud")
				Snacks.toggle.line_number():map("<leader>ul")
				Snacks.toggle
					.option("conceallevel", {
						off = 0,
						on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
					})
					:map("<leader>uc")
				Snacks.toggle.treesitter():map("<leader>uT")
				Snacks.toggle
					.option("background", {
						off = "light",
						on = "dark",
						name = "Dark Background",
					})
					:map("<leader>ub")
				Snacks.toggle.inlay_hints():map("<leader>uh")
				Snacks.toggle.indent():map("<leader>ug")
				Snacks.toggle.dim():map("<leader>uD")
			end,
		})
	end,
}
