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
	local dir_icon = "  "
	local dir_name = fn.fnamemodify(fn.getcwd(), ":t")
	return (vim.o.columns > 85 and (dir_icon .. dir_name)) or ""
end

local function mode()
	return " "
end

local options = {
	options = {
		icons_enabled = true,
		theme = "tokyonight",
		-- theme = "everforest",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "help", "NvimTree", "alpha" },
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
			{ cwd, color = { fg = "#7aa2f7", bg = "#2f344d" }, separator = { right = "" } }, -- tokyonight
			-- { cwd, color = { fg = "#83c092", bg = "#374145" } }, -- everforest
			{
				"filename",
				file_status = true,
				newfile_status = true,
				path = 1,
				shorting_target = 30,
				separator = { right = "" },
				color = { fg = "#c0caf5", bg = "#292e42" }, -- tokyonight
				-- color = { fg = "#9da9a0", bg = "#2e383c" }, -- everforest
			},
		},
		lualine_c = { { "branch", icon = "" }, "diff" },
		lualine_x = { "diagnostics" },
		lualine_y = { "location" },
		lualine_z = { lsp_status },
	},
	inactive_sections = {
		lualine_a = { mode },
		lualine_b = {
			{ cwd },
			{
				"filename",
				file_status = true,
				newfile_status = true,
				path = 1,
				shorting_target = 30,
				color = { fg = "#c0caf5", bg = "#292e42" }, -- tokyonight
				-- color = { fg = "#9da9a0", bg = "#2e383c" }, -- everforest
			},
		},
		lualine_c = { { "branch", icon = "" }, "diff" },
		lualine_x = { "diagnostics" },
		lualine_y = { "location" },
		lualine_z = { lsp_status },
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
}

require("lualine").setup(options)
