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

M.clipboard_to_qf = function()
	local files = vim.split(vim.fn.getreg("+"), "\n", { trimempty = true })
	vim.fn.setqflist(vim.tbl_map(function(f)
		return { filename = f, lnum = 1 }
	end, files))
	vim.cmd("copen")
end

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

local function find_jj_root()
	local jj_dir = vim.fn.finddir(".jj", ".;")
	return jj_dir ~= "" and vim.fn.fnamemodify(jj_dir, ":h") or vim.uv.cwd()
end

local function first_changed_line_offset(diff)
	local offset = 0
	for line in diff:gmatch("[^\n]+") do
		if line:match("^diff ") or line:match("^index ") or line:match("^%-%-%-") or line:match("^%+%+%+") or line:match("^@@") then
			-- skip diff header lines
		elseif line:match("^ ") then
			offset = offset + 1
		else
			break
		end
	end
	return offset
end

local function close_dashboard_windows()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
			local bufnr = vim.api.nvim_win_get_buf(win)
			local filetype = vim.bo[bufnr].filetype
			if filetype == "snacks_dashboard" or filetype == "alpha" then
				pcall(vim.api.nvim_win_close, win, true)
			end
		end
	end
end

M.jj_diff_hunks_to_qf = function(revset)
	local cwd = find_jj_root()
	local cmd = { "jj", "diff", "--git" }
	if revset then
		vim.list_extend(cmd, { "-r", revset })
	end
	local result = vim.system(cmd, { cwd = cwd, text = true }):wait()

	if result.code ~= 0 then
		vim.notify(result.stderr ~= "" and result.stderr or "jj diff failed", vim.log.levels.ERROR)
		return
	end

	local diff = require("snacks.picker.source.diff").parse(vim.split(result.stdout, "\n", { plain = true }))
	local qf_entries = {}
	for _, block in ipairs(diff.blocks) do
		for _, hunk in ipairs(block.hunks) do
			local hunk_diff = table.concat(vim.list_extend(vim.deepcopy(block.header), hunk.diff), "\n")
			qf_entries[#qf_entries + 1] = {
				filename = vim.fs.joinpath(cwd, block.file),
				lnum = hunk.line + first_changed_line_offset(hunk_diff),
				col = 1,
				text = block.file .. ":" .. hunk.line,
				valid = true,
			}
		end
	end

	if vim.tbl_isempty(qf_entries) then
		vim.notify("No changed hunks found", vim.log.levels.INFO)
		return
	end

	vim.fn.setqflist({}, "r", { title = "JJ Diff " .. (revset or "@"), items = qf_entries })
	vim.cmd("cfirst")
	close_dashboard_windows()
	vim.cmd("botright copen")
end

local STACK_REVSET = "trunk()..@"

local function list_stack_commits(cwd)
	local template = table.concat({
		"change_id.shortest(8)",
		"self.diff().files().len()",
		'if(self.contained_in("trunk()"), "trunk", "")',
		"bookmarks",
		"description.first_line()",
	}, ' ++ "\\t" ++ ') .. ' ++ "\\n"'
	local result = vim.system(
		{ "jj", "log", "--no-graph", "--color=never", "-r", "trunk()::@", "-T", template },
		{ cwd = cwd, text = true }
	):wait()
	if result.code ~= 0 then
		return nil, result.stderr ~= "" and result.stderr or "jj log failed"
	end

	local commits = {}
	for line in result.stdout:gmatch("[^\n]+") do
		local fields = vim.split(line, "\t", { plain = true })
		commits[#commits + 1] = {
			change_id = fields[1],
			files_changed = tonumber(fields[2]) or 0,
			is_trunk = fields[3] == "trunk",
			bookmarks = fields[4],
			summary = table.concat(vim.list_slice(fields, 5), "\t"),
		}
	end
	return commits
end

local function stack_choice_label(choice)
	if choice.revset == STACK_REVSET then
		return "[select all] " .. STACK_REVSET
	end
	local commit = choice.commit
	if commit.is_trunk then
		return ("[main - %s] %s"):format(commit.change_id, commit.bookmarks ~= "" and commit.bookmarks or commit.summary)
	end
	local summary = commit.summary ~= "" and commit.summary or "(no description)"
	return ("[%s] ~%d %s"):format(commit.change_id, commit.files_changed, summary)
end

M.jj_pick_diff_to_qf = function()
	local commits, err = list_stack_commits(find_jj_root())
	if not commits then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	local choices = { { revset = STACK_REVSET } }
	for _, commit in ipairs(commits) do
		choices[#choices + 1] = { revset = commit.change_id, commit = commit }
	end

	vim.ui.select(choices, { prompt = "Diff to quickfix", format_item = stack_choice_label }, function(choice)
		if choice then
			M.jj_diff_hunks_to_qf(choice.revset)
		end
	end)
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

-- Get the default branch for the current git repo
M.get_default_branch = function()
	-- Try to get the default branch from remote HEAD
	local handle = io.popen("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'")
	if handle then
		local result = handle:read("*a")
		handle:close()
		result = result:gsub("%s+", "")
		if result ~= "" then
			return result
		end
	end

	-- Fallback: check for common branch names
	for _, branch in ipairs({ "main", "master", "staging" }) do
		local check = io.popen("git show-ref --verify --quiet refs/heads/" .. branch .. " 2>/dev/null && echo 'exists'")
		if check then
			local exists = check:read("*a")
			check:close()
			if exists:match("exists") then
				return branch
			end
		end
	end

	return "main" -- final fallback
end

-- Browse file on default branch in GitLab
M.browse_default_branch = function()
	local branch = M.get_default_branch()
	vim.cmd(".GBrowse! " .. branch .. ":%")
end

M.oil_toggle = function()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_filetype = vim.bo[current_buf].filetype

	if current_filetype == "oil" then
		require("oil").close()
	else
		vim.cmd("Oil")
	end
end

return M
