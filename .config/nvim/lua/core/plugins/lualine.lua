local fn = vim.fn

-- Define statusline highlight groups for tokyonight
local function setup_tokyonight_highlights()
	-- Mode indicator
	vim.api.nvim_set_hl(0, "StatusLineMode", {})

	-- Git highlights
	vim.api.nvim_set_hl(0, "StatusLineGitBranchIcon", { fg = "#ff9e64" })
	vim.api.nvim_set_hl(0, "StatusLineBranch", { fg = "#a9b1d6" })
	vim.api.nvim_set_hl(0, "StatusLineGitDiffAdded", { fg = "#c3e88d" })
	vim.api.nvim_set_hl(0, "StatusLineGitDiffChanged", { fg = "#ffc777" })
	vim.api.nvim_set_hl(0, "StatusLineGitDiffRemoved", { fg = "#ff757f" })

	-- LSP highlights
	vim.api.nvim_set_hl(0, "StatusLineLspError", { fg = "#ff757f" })
	vim.api.nvim_set_hl(0, "StatusLineLspWarn", { fg = "#ffc777" })
	vim.api.nvim_set_hl(0, "StatusLineLspHint", { fg = "#4fd6be" })
	vim.api.nvim_set_hl(0, "StatusLineLspInfo", { fg = "#c3e88d" })
	vim.api.nvim_set_hl(0, "StatusLineLspMessages", { fg = "#7dcfff", italic = true })

	-- General highlights
	vim.api.nvim_set_hl(0, "StatusLineMedium", { fg = "#737aa2" })
	vim.api.nvim_set_hl(0, "StatusLineModified", { fg = "#41a6b5" })
	vim.api.nvim_set_hl(0, "StatusLineFilename", { fg = "#a9b1d6" })
end

-- Define statusline highlight groups for gruvbox
local function setup_gruvbox_highlights()
	-- Mode indicator
	vim.api.nvim_set_hl(0, "StatusLineMode", {})

	-- Git highlights
	vim.api.nvim_set_hl(0, "StatusLineGitBranchIcon", { fg = "#fe8019" }) -- orange
	vim.api.nvim_set_hl(0, "StatusLineBranch", { fg = "#ebdbb2" }) -- fg1
	vim.api.nvim_set_hl(0, "StatusLineGitDiffAdded", { fg = "#b8bb26" }) -- green
	vim.api.nvim_set_hl(0, "StatusLineGitDiffChanged", { fg = "#fabd2f" }) -- yellow
	vim.api.nvim_set_hl(0, "StatusLineGitDiffRemoved", { fg = "#fb4934" }) -- red

	-- LSP highlights
	vim.api.nvim_set_hl(0, "StatusLineLspError", { fg = "#fb4934" }) -- red
	vim.api.nvim_set_hl(0, "StatusLineLspWarn", { fg = "#fabd2f" }) -- yellow
	vim.api.nvim_set_hl(0, "StatusLineLspHint", { fg = "#8ec07c" }) -- aqua
	vim.api.nvim_set_hl(0, "StatusLineLspInfo", { fg = "#b8bb26" }) -- green
	vim.api.nvim_set_hl(0, "StatusLineLspMessages", { fg = "#83a598", italic = true }) -- blue

	-- General highlights
	vim.api.nvim_set_hl(0, "StatusLineMedium", { fg = "#928374" }) -- gray
	vim.api.nvim_set_hl(0, "StatusLineModified", { fg = "#689d6a" }) -- teal
	vim.api.nvim_set_hl(0, "StatusLineFilename", { fg = "#ebdbb2" }) -- fg1
end

local function lsp_status()
	local ok, devicons = pcall(require, "nvim-web-devicons")
	local icon = " " -- Default icon

	if ok then
		local f_name, f_extension = vim.fn.expand("%:t"), vim.fn.expand("%:e")
		-- Use filetype as fallback extension only if there's a filename
		if f_name ~= "" then
			f_extension = f_extension ~= "" and f_extension or vim.bo.filetype
			local found_icon, _ = devicons.get_icon(f_name, f_extension, { default = true })
			if found_icon and found_icon ~= "" then
				icon = found_icon .. " "
			end
		end
	else
		if vim.fn.exists("*WebDevIconsGetFileTypeSymbol") == 1 then
			local found_icon = vim.fn.WebDevIconsGetFileTypeSymbol()
			if found_icon and found_icon ~= "" then
				icon = found_icon .. " "
			end
		end
	end

	if not vim.lsp then
		return icon
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })

	local active_clients_info = {}
	local active_client_count = 0
	local clients_to_exclude = {
		tailwindcss = true,
		["GitHub Copilot"] = true,
	}

	if #clients > 0 then
		for _, client in ipairs(clients) do
			if client.name and not clients_to_exclude[client.name] then
				active_client_count = active_client_count + 1
				local client_name = client.name
				local status_indicator = ""

				local is_ready_ok, is_ready = pcall(function()
					return client.is_ready()
				end)

				if is_ready_ok and not is_ready then
					status_indicator = "*"
				end

				table.insert(active_clients_info, client_name .. status_indicator)
			end
		end
	end

	local lsp_string = table.concat(active_clients_info, ", ")

	if lsp_string == "" then
		return icon
	end

	if vim.o.columns > 100 then
		return icon .. lsp_string
	else
		return icon .. "[" .. active_client_count .. "]"
	end
end

local function modified_indicator()
	if vim.bo.modified then
		return "•"
	else
		return ""
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

local project_root_cache = {}

-- Clear cache when buffers are wiped out to prevent memory leaks
vim.api.nvim_create_autocmd("BufWipeout", {
	pattern = "*",
	callback = function(args)
		project_root_cache[args.buf] = nil
	end,
})

local function get_project_root(bufnr)
	-- Check cache first
	if project_root_cache[bufnr] ~= nil then
		return project_root_cache[bufnr]
	end

	-- Determine root: Try Git first
	local git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"))

	local root_dir
	if git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
		root_dir = git_root
	else
		-- Fallback to current working directory if Git fails or isn't a directory
		root_dir = vim.fn.getcwd()
	end

	-- Cache the result (even if it's just CWD)
	-- Store false if CWD also somehow fails, to prevent retrying getcwd constantly
	project_root_cache[bufnr] = root_dir or false
	return project_root_cache[bufnr]
end

local function path()
	local bufnr = vim.api.nvim_get_current_buf()
	local current_file_path = vim.api.nvim_buf_get_name(bufnr) -- More direct way to get full path

	-- Handle unnamed buffers or buffers without a file path
	if current_file_path == "" then
		return " "
	end

	local root_dir = get_project_root(bufnr)

	-- If we couldn't determine a root (e.g., getcwd failed - very unlikely), bail out
	if not root_dir then
		return " "
	end

	-- Ensure root_dir ends with a path separator for reliable matching
	local path_sep = package.config:sub(1, 1) -- '/' on Unix/Linux/Mac, '\' on Windows
	if not root_dir:find(path_sep .. "$") then -- Check if it doesn't end with separator
		root_dir = root_dir .. path_sep
	end

	local relative_path
	-- Check if the file path starts with the root directory path
	if current_file_path:find(root_dir, 1, true) == 1 then
		-- Extract the part after the root directory
		relative_path = current_file_path:sub(#root_dir + 1)
	else
		-- File is not inside the determined project root, display nothing for relative path
		return " "
	end

	-- Get the directory part of the relative path
	local relative_dir = vim.fn.fnamemodify(relative_path, ":h")

	-- If the file is directly in the root (e.g., "README.md"), :h returns "."
	-- Or if the relative path had no directory part (e.g. root was '/')
	if relative_dir == "." or relative_dir == "" then
		return " " -- Don't show anything if it's directly in the root
	end

	-- Shorten the directory path: f/b/baz/ -> f/b/baz/
	local parts = {}
	local count = 0
	-- Split by path separator
	for part in string.gmatch(relative_dir, "[^" .. path_sep .. "]+") do
		table.insert(parts, part)
		count = count + 1
	end

	if count == 0 then
		return " " -- Should not happen if relative_dir was not empty, but safety check
	elseif count == 1 then
		-- Don't shorten if only one directory deep
		return parts[1] .. path_sep
	else
		local shortened_parts = {}
		for i = 1, count - 1 do
			-- Take the first character of intermediate directories
			table.insert(shortened_parts, parts[i]:sub(1, 1))
		end
		-- Add the last directory name fully
		table.insert(shortened_parts, parts[count])

		-- Join with separator and add trailing separator
		return table.concat(shortened_parts, path_sep) .. path_sep
	end
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

-- LSP progress tracking
local statusline_augroup = vim.api.nvim_create_augroup("gmr_statusline", { clear = true })

--- @class LspProgress
--- @field client vim.lsp.Client?
--- @field kind string?
--- @field title string?
--- @field percentage integer?
--- @field message string?
local lsp_progress = {
	client = nil,
	kind = nil,
	title = nil,
	percentage = nil,
	message = nil,
}

vim.api.nvim_create_autocmd("LspProgress", {
	group = statusline_augroup,
	desc = "Update LSP progress in statusline",
	pattern = { "begin", "report", "end" },
	callback = function(args)
		if not (args.data and args.data.client_id) then
			return
		end

		-- Check if params and value exist before accessing their properties
		local params = args.data.params or {}
		local value = params.value or {}

		lsp_progress = {
			client = vim.lsp.get_client_by_id(args.data.client_id),
			kind = value.kind,
			message = value.message,
			percentage = value.percentage,
			title = value.title,
		}

		if lsp_progress.kind == "end" then
			lsp_progress.title = nil
			vim.defer_fn(function()
				vim.cmd.redrawstatus()
			end, 500)
		else
			vim.cmd.redrawstatus()
		end
	end,
})

-- Color scheme detection and mapping system
local function get_current_colorscheme()
	local colorscheme = vim.g.colors_name or ""
	if colorscheme:match("tokyonight") then
		return "tokyonight"
	elseif colorscheme:match("gruvbox") then
		return "gruvbox"
	else
		return "tokyonight" -- default fallback
	end
end

-- Color mappings for different themes
local color_schemes = {
	tokyonight = {
		-- Lualine section colors
		mode_bg = "#6d91db",
		mode_fg = "#1a1b26",
		cwd_fg = "#7aa2f7",
		cwd_bg = "#2f344d",
		path_fg = "#737aa2",
		path_bg = "#212435",
		filename_fg = "#a9b1d6",
		filename_bg = "#212435",
		modified_fg = "#41a6b5",
		modified_bg = "#212435",
		-- Git component colors
		git_branch_fg = "#7aa2f7",
		git_added_fg = "#9ece6a",
		git_modified_fg = "#e0af68",
		git_removed_fg = "#f7768e",
		-- Theme name
		theme = "tokyonight",
	},
	gruvbox = {
		-- Lualine section colors
		mode_bg = "#fe8019", -- orange
		mode_fg = "#1d2021", -- bg0_h
		cwd_fg = "#83a598", -- blue
		cwd_bg = "#3c3836", -- bg1
		path_fg = "#928374", -- gray
		path_bg = "#32302f", -- bg0_s
		filename_fg = "#ebdbb2", -- fg1
		filename_bg = "#32302f", -- bg0_s
		modified_fg = "#689d6a", -- teal
		modified_bg = "#32302f", -- bg0_s
		-- Git component colors
		git_branch_fg = "#83a598", -- blue
		git_added_fg = "#b8bb26", -- green
		git_modified_fg = "#fabd2f", -- yellow
		git_removed_fg = "#fb4934", -- red
		-- Theme name
		theme = "gruvbox",
	},
}

-- Get colors for current theme
local function get_colors()
	local current_scheme = get_current_colorscheme()
	return color_schemes[current_scheme]
end

-- Generate lualine options with dynamic colors
local function get_lualine_options()
	local colors = get_colors()

	return {
		options = {
			icons_enabled = true,
			theme = colors.theme,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			disabled_filetypes = {
				statusline = { "help", "NvimTree", "alpha", "Avante", "AvanteSelectedFiles", "AvanteInput" },
				winbar = {},
			},
			ignore_focus = {},
			always_divide_middle = true,
			globalstatus = false,
			refresh = {
				statusline = 100,
			},
		},
		sections = {
			lualine_a = {
				{
					mode,
					fmt = function(str)
						return str
					end,
					color = { bg = colors.mode_bg, fg = colors.mode_fg, bold = true },
				},
			},
			lualine_b = {
				{ cwd, color = { fg = colors.cwd_fg, bg = colors.cwd_bg } },
				{ path, color = { fg = colors.path_fg, bg = colors.path_bg }, padding = { left = 1, right = 0 } },
				{
					"filename",
					file_status = false,
					newfile_status = false,
					path = 0,
					padding = { left = 0, right = 1 },
					color = { fg = colors.filename_fg, bg = colors.filename_bg },
				},
				{
					modified_indicator,
					color = { fg = colors.modified_fg, bg = colors.modified_bg },
					padding = { left = 0, right = 1 },
				},
			},
			lualine_c = { full_git },
			lualine_x = { "diagnostics" },
			lualine_y = { "location" },
			lualine_z = { lsp_status },
		},
		inactive_sections = {
			lualine_a = {
				{
					mode,
					fmt = function(str)
						return str
					end,
					color = { bg = colors.mode_bg, fg = colors.mode_fg, bold = true },
				},
			},
			lualine_b = {
				{ cwd, color = { fg = colors.cwd_fg, bg = colors.cwd_bg } },
				{ path, color = { fg = colors.path_fg, bg = colors.path_bg }, padding = { left = 1, right = 0 } },
				{
					"filename",
					file_status = false,
					newfile_status = false,
					path = 0,
					padding = { left = 0, right = 1 },
					color = { fg = colors.filename_fg, bg = colors.filename_bg },
				},
				{
					modified_indicator,
					color = { fg = colors.modified_fg, bg = colors.modified_bg },
					padding = { left = 0, right = 1 },
				},
			},
		},
		tabline = {},
		winbar = {},
		inactive_winbar = {},
		extensions = {},
	}
end

local colorscheme = vim.g.colors_name or ""

if colorscheme:match("tokyonight") then
	setup_tokyonight_highlights()
end

if colorscheme:match("gruvbox-baby") then
	setup_gruvbox_highlights()
end

require("lualine").setup(get_lualine_options())
