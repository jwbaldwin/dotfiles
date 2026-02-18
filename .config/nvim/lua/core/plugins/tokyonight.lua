local options = {
	style = "night",
	transparent = true,
	terminal_colors = true,
	styles = {
		comments = { italic = true },
		keywords = { italic = true, bold = true },
		functions = {},
		variables = {},
		floats = "transparent",
		sidebars = "transparent",
	},
	sidebars = { "qf", "vista_kind", "packer" },
	hide_inactive_statusline = true,
	lualine_bold = true,
	on_highlights = function(hl, c)
		-- Define function definition keyword color
		hl["@keyword.function"] = { fg = c.magenta, italic = true, bold = true }

		-- Control flow keywords bold
		hl["@keyword.return"] = { fg = c.magenta, bold = true }
		hl["@keyword.conditional"] = { fg = c.magenta, bold = true }

		-- Special syntax elements
		hl.Special = { fg = c.yellow }

		-- Preprocessor elements
		hl["@module"] = { fg = c.blue1 }
	end,
}

require("tokyonight").setup(options)

-- :TSHighlightCapturesUnderCursor for finding HL group under cursor
