local M = {}
-- Helper for yanking stuff in remaps
M.yank = function(stuff)
	if stuff then
		vim.fn.setreg("+", stuff)
		return print("yanked:", stuff)
	else
		return print("nothing to yank.")
	end
end

local merge_table = vim.tbl_deep_extend

M.toggle_qf_list = function()
	local qf_exists = false
	for _, win in pairs(vim.fn.getwininfo()) do
		if win["quickfix"] == 1 then
			qf_exists = true
		end
	end
	if qf_exists == true then
		vim.cmd("cclose")
		return
	end
	if not vim.tbl_isempty(vim.fn.getqflist()) then
		vim.cmd("copen")
	end
end

M.close_buffer = function(bufnr)
	if vim.bo.buftype == "terminal" then
		vim.cmd(vim.bo.buflisted and "set nobl | enew" or "hide")
	else
		bufnr = bufnr or vim.api.nvim_get_current_buf()
		vim.cmd("confirm bd" .. bufnr)
	end
end

M.mason_cmds = {
	"Mason",
	"MasonInstall",
	"MasonInstallAll",
	"MasonUninstall",
	"MasonUninstallAll",
	"MasonLog",
}

M.load_mappings = function(section, mapping_opt)
	local function set_section_map(section_values)
		for mode, mode_values in pairs(section_values) do
			local default_opts = merge_table("force", { mode = mode }, mapping_opt or {})
			for keybind, mapping_info in pairs(mode_values) do
				-- merge default + user opts
				local opts = merge_table("force", default_opts, mapping_info.opts or {})

				mapping_info.opts, opts.mode = nil, nil
				opts.desc = mapping_info[2]

				vim.keymap.set(mode, keybind, mapping_info[1], opts)
			end
		end
	end

	-- My keymaps are loaded here, this allows for special config
	local mappings = require("core.keymaps")

	if type(section) == "string" then
		mappings = { mappings[section] }
	end

	for _, sect in pairs(mappings) do
		set_section_map(sect)
	end
end

-- Functions for extracting module names from Elixir files
local function extract_elixir_module_parts(full_module_name)
	assert(full_module_name)
	local tbl_17_auto = {}
	local i_18_auto = #tbl_17_auto
	for part in full_module_name:gmatch("([^%.]+)") do
		local val_19_auto = part
		if nil ~= val_19_auto then
			i_18_auto = (i_18_auto + 1)
			do
			end
			(tbl_17_auto)[i_18_auto] = val_19_auto
		else
		end
	end
	return tbl_17_auto
end

local function get_full_elixir_module()
	local first_line = vim.fn.getline(1)
	return first_line:match("defmodule%s+([%w_%.]+)%s+do")
end

M.current_absolute_module = function()
	return get_full_elixir_module()
end

M.current_local_module = function()
	local module_parts
	do
		local _2_ = get_full_elixir_module()
		if nil ~= _2_ then
			module_parts = extract_elixir_module_parts(_2_)
		else
			module_parts = _2_
		end
	end
	local t_4_ = module_parts
	if nil ~= t_4_ then
		t_4_ = (t_4_)[#module_parts]
	else
	end
	return t_4_
end

M.oil_toggle = function()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_filetype = vim.api.nvim_buf_get_option(current_buf, "filetype")

	if current_filetype == "oil" then
		-- We use a command to go to the previous buffer
		require("oil").close()
	else
		-- Open oil if not already in an oil buffer
		vim.cmd("Oil")
	end
end

return M
