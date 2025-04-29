-- Statusline highlight groups - tokyonight
--
return {
	-- Mode indicator
	StatusLineMode = {},

	-- Git highlights
	StatusLineGitBranchIcon = { fg = "#ff9e64" },
	StatusLineBranch = { fg = "#a9b1d6" },
	StatusLineGitDiffAdded = { fg = "#c3e88d" },
	StatusLineGitDiffChanged = { fg = "#ffc777" },
	StatusLineGitDiffRemoved = { fg = "#ff757f" },

	-- LSP highlights
	StatusLineLspError = { fg = "#ff757f" },
	StatusLineLspWarn = { fg = "#ffc777" },
	StatusLineLspHint = { fg = "#4fd6be" },
	StatusLineLspInfo = { fg = "#c3e88d" },
	StatusLineLspMessages = { fg = "#7dcfff", italic = true },

	-- General highlights
	StatusLineMedium = { fg = "#737aa2" },
	StatusLineModified = { fg = "#41a6b5" },
	StatusLineFilename = { fg = "#a9b1d6" },
}
