-- Statusline highlight groups - tokyonight
--
-- return {
-- 	-- Mode indicator
-- 	StatusLineMode = { bg = "#6d91db", fg = "#1a1b26", bold = true },
--
-- 	-- Git highlights
-- 	StatusLineGitBranchIcon = { fg = "#bb7a8c" },
-- 	StatusLineGitDiffAdded = { fg = "#8fbd6b" },
-- 	StatusLineGitDiffChanged = { fg = "#bd9867" },
-- 	StatusLineGitDiffRemoved = { fg = "#db5d6d" },
--
-- 	-- LSP highlights
-- 	StatusLineLspError = { fg = "#db5d6d" },
-- 	StatusLineLspWarn = { fg = "#bd9867" },
-- 	StatusLineLspHint = { fg = "#6d91db" },
-- 	StatusLineLspInfo = { fg = "#8fbd6b" },
-- 	StatusLineLspMessages = { fg = "#73c6e6", italic = true },
--
-- 	-- General highlights
-- 	StatusLineMedium = { fg = "#9da3b9" },
-- }

return {
	-- Mode indicator
	StatusLineMode = { bg = "#a7c080", fg = "#2d353b", bold = true },

	-- Git highlights
	StatusLineGitBranchIcon = { fg = "#d699b6" },
	StatusLineGitDiffAdded = { fg = "#83c092" },
	StatusLineGitDiffChanged = { fg = "#dbbc7f" },
	StatusLineGitDiffRemoved = { fg = "#e67e80" },

	-- LSP highlights
	StatusLineLspError = { fg = "#e67e80" },
	StatusLineLspWarn = { fg = "#dbbc7f" },
	StatusLineLspHint = { fg = "#7fbbb3" },
	StatusLineLspInfo = { fg = "#83c092" },
	StatusLineLspMessages = { fg = "#7fbbb3", italic = true },

	-- General highlights
	StatusLineMedium = { fg = "#9da9a0" },
	StatusLineModified = { fg = "#9EBC9F" },
}
