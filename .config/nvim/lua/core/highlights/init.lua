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

	-- Set up indent guide highlights to be more subtle
	local function setup_indent_highlights()
		-- Get the background color
		local bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg or 0x1a1b26

		-- Create very subtle colors based on the background
		local function blend_with_bg(bg_color, opacity)
			local r = math.floor((bg_color / 65536) % 256)
			local g = math.floor((bg_color / 256) % 256)
			local b = math.floor(bg_color % 256)

			-- Slightly brighten for dark themes
			r = math.min(255, r + opacity)
			g = math.min(255, g + opacity)
			b = math.min(255, b + opacity)

			return string.format("#%02x%02x%02x", r, g, b)
		end

		-- Very subtle inactive guides (barely visible)
		vim.api.nvim_set_hl(0, "SnacksIndent", { fg = blend_with_bg(bg, 10) })

		-- Keep the active/scope guide as teal (tokyonight teal color)
		vim.api.nvim_set_hl(0, "SnacksIndentScope", {
			fg = "#1abc9c",
			bold = false,
			italic = false,
			underline = false,
		})
	end

	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = setup_indent_highlights,
	})

	-- Apply immediately for current colorscheme
	setup_indent_highlights()
end

return M
