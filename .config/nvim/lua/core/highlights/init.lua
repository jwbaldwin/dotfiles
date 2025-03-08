local M = {}

function M.setup()
	-- Load all highlight groups
	local highlights = {
		require("core.highlights.statusline"),
		-- Add other highlight group files here
	}

	-- Apply all highlight groups
	for _, group in ipairs(highlights) do
		for name, opts in pairs(group) do
			vim.api.nvim_set_hl(0, name, opts)
		end
	end
end

return M
