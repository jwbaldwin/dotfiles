-- Statusline highlight groups - tokyonight
--
return {
	-- Mode indicator
	StatusLineMode = { bg = "#6d91db", fg = "#1a1b26", bold = true },

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

-- return {
-- 	-- Mode indicator
-- 	StatusLineMode = { bg = "#a7c080", fg = "#2d353b", bold = true },
--
-- 	-- Git highlights
-- 	StatusLineGitBranchIcon = { fg = "#d699b6" },
-- 	StatusLineGitDiffAdded = { fg = "#83c092" },
-- 	StatusLineGitDiffChanged = { fg = "#dbbc7f" },
-- 	StatusLineGitDiffRemoved = { fg = "#e67e80" },
--
-- 	-- LSP highlights
-- 	StatusLineLspError = { fg = "#e67e80" },
-- 	StatusLineLspWarn = { fg = "#dbbc7f" },
-- 	StatusLineLspHint = { fg = "#7fbbb3" },
-- 	StatusLineLspInfo = { fg = "#83c092" },
-- 	StatusLineLspMessages = { fg = "#7fbbb3", italic = true },
--
-- 	-- General highlights
-- 	StatusLineMedium = { fg = "#9da9a0" },
-- 	StatusLineModified = { fg = "#9EBC9F" },
-- }
