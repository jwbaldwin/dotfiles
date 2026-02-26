require("tokyonight").setup({
	style = "night",
	transparent = true,
	styles = {
		keywords = { italic = true },
		comments = { italic = true },
		sidebars = "transparent",
		floats = "transparent",
	},
	on_highlights = function(highlights, colors)
		highlights["@module.elixir"] = { fg = colors.blue1 }
		highlights["@constant.builtin.elixir"] = { fg = colors.yellow }
		highlights["@function.builtin.elixir"] = { fg = colors.yellow }
		highlights["@keyword.function.elixir"] = { fg = colors.magenta, italic = true }
	end,
})
