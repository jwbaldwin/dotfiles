local fn = vim.fn

local function lsp_status()
	local ok, devicons = pcall(require, "nvim-web-devicons")
	local icon = ""
	local icon_highlight_group = ""
	if ok then
		local f_name, f_extension = vim.fn.expand("%:t"), vim.fn.expand("%:e")
		f_extension = f_extension ~= "" and f_extension or vim.bo.filetype
		icon, icon_highlight_group = devicons.get_icon(f_name, f_extension)

		if icon == nil and icon_highlight_group == nil then
			icon = " "
		end
	else
		ok = vim.fn.exists("*WebDevIconsGetFileTypeSymbol")
		if ok ~= 0 then
			icon = vim.fn.WebDevIconsGetFileTypeSymbol()
		end
	end
	if rawget(vim, "lsp") then
		for _, client in ipairs(vim.lsp.get_active_clients()) do
			if client.name ~= "tailwindcss" then
				if client.attached_buffers[vim.api.nvim_get_current_buf()] then
					return (vim.o.columns > 100 and client.name .. " " .. icon) or "LSP  "
				end
			end
		end
	end
end

local function cwd()
	local dir_name = fn.fnamemodify(fn.getcwd(), ":t")
	return (vim.o.columns > 85 and dir_name) or ""
end

--- @return string
local function mode()
	return vim.api.nvim_get_mode().mode
end

--- @param type string
--- @return integer
local function get_git_diff(type)
	local gsd = vim.b.gitsigns_status_dict
	if gsd and gsd[type] then
		return gsd[type]
	end

	return 0
end

---
--- @return string
local function git_diff_added()
	local added = get_git_diff("added")
	if added > 0 then
		return string.format("%%#StatusLineGitDiffAdded#+%s%%*", added)
	end

	return ""
end

--- @return string
local function git_diff_changed()
	local changed = get_git_diff("changed")
	if changed > 0 then
		return string.format("%%#StatusLineGitDiffChanged#~%s%%*", changed)
	end

	return ""
end

--- @return string
local function git_diff_removed()
	local removed = get_git_diff("removed")
	if removed > 0 then
		return string.format("%%#StatusLineGitDiffRemoved#-%s%%*", removed)
	end

	return ""
end

--- @return string
local function git_branch_icon()
	return "%#StatusLineGitBranchIcon#%*"
end

--- @return string
local function git_branch()
	local branch = vim.b.gitsigns_head

	if branch == "" or branch == nil then
		return ""
	end

	return string.format("%%#StatusLineMedium#%s%%*", branch)
end

--- @return string
-- Original full_git function that uses highlight groups
local function full_git()
	local full = ""
	local space = "%#StatusLineMedium# %*"

	local branch = git_branch()
	if branch ~= "" then
		local icon = git_branch_icon()
		full = full .. space .. icon .. space .. branch .. space
	end

	local added = git_diff_added()
	if added ~= "" then
		full = full .. added .. space
	end

	local changed = git_diff_changed()
	if changed ~= "" then
		full = full .. changed .. space
	end

	local removed = git_diff_removed()
	if removed ~= "" then
		full = full .. removed .. space
	end

	return full
end

-- Lualine compatible git components
local git_components = {
	branch = {
		function()
			local branch = vim.b.gitsigns_head
			return branch or ""
		end,
		icon = "",
		color = { fg = "#7aa2f7" },
	},
	diff = {
		"diff",
		colored = true,
		symbols = { added = "+", modified = "~", removed = "-" },
		color_added = { fg = "#9ece6a" },
		color_modified = { fg = "#e0af68" },
		color_removed = { fg = "#f7768e" },
	},
}

local options = {
	options = {
		icons_enabled = true,
		theme = "tokyonight",
		-- theme = "everforest",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "help", "NvimTree", "alpha", "Avante", "AvanteSelectedFiles", "AvanteInput" },
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		globalstatus = false,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	sections = {
		lualine_a = { mode },
		lualine_b = {
			{ cwd, color = { fg = "#7aa2f7", bg = "#2f344d" } }, -- tokyonight
			-- { cwd, color = { fg = "#83c092", bg = "#374145" } }, -- everforest
			{
				"filename",
				file_status = true,
				newfile_status = true,
				path = 1,
				shorting_target = 30,
				separator = { right = "" },
				color = { fg = "#9aa3c4", bg = "#212435" }, -- tokyonight
				-- color = { fg = "#9da9a0", bg = "#2e383c" }, -- everforest
			},
		},
		lualine_c = { full_git },
		lualine_x = { "diagnostics" },
		lualine_y = { "location" },
		lualine_z = { lsp_status },
	},
	inactive_sections = {},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
}

require("lualine").setup(options)
