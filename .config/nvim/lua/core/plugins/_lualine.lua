-- local separators = require("core.icons").statusline_separators["block"]
-- local sep_l = separators["right"]
local fn = vim.fn

-- LSP STUFF
-- local function lsp_progress()
--   if not rawget(vim, "lsp") then
--     return ""
--   end
--
--   local Lsp = vim.lsp.util.get_progress_messages()[1]
--
--   if vim.o.columns < 120 or not Lsp then
--     return ""
--   end
--
--   local msg = Lsp.message or ""
--   local percentage = Lsp.percentage or 0
--   local title = Lsp.title or ""
--   local spinners = { "", "" }
--   local ms = vim.loop.hrtime() / 1000000
--   local frame = math.floor(ms / 120) % #spinners
--   local content = string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)
--
--   return ("%#St_LspProgress#" .. content) or ""
--  -- end

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
			if client.attached_buffers[vim.api.nvim_get_current_buf()] then
				return (vim.o.columns > 100 and client.name .. " " .. icon) or "LSP  "
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
		section_separators = { left = "", right = "" },
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
			{ cwd, color = { fg = "#7aa2f7", bg = "#2f344d" } }, -- tokyonight
			-- { cwd, color = { fg = "#83c092", bg = "#374145" } }, -- everforest
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
		lualine_c = { { "branch", icon = "" }, "diff", "diagnostics" },
		lualine_x = { lsp_status },
		lualine_y = { "location" },
		lualine_z = { "progress" },
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
		lualine_c = { { "branch", icon = "" }, "diff", "diagnostics" },
		lualine_x = { lsp_status },
		lualine_y = { "location" },
		lualine_z = { "progress" },
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
}

require("lualine").setup(options)
