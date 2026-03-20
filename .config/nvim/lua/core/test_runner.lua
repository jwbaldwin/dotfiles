local M = {}

local function is_elixir()
	return vim.bo.filetype == "elixir"
end

local function has_mix_test_interactive()
	vim.fn.system({ "mix", "help", "test.interactive" })
	return vim.v.shell_error == 0
end

local function parent_dir(path)
	return vim.fn.fnamemodify(path, ":h")
end

local function find_nearest_file(start_dir, candidates)
	local dir = start_dir

	while dir and dir ~= "" do
		for _, candidate in ipairs(candidates) do
			local full_path = dir .. "/" .. candidate
			if vim.fn.filereadable(full_path) == 1 then
				return dir, candidate
			end
		end

		local next_dir = parent_dir(dir)
		if next_dir == dir then
			break
		end
		dir = next_dir
	end
end

-- Ensure we're in the right directory before running tests (for monorepos)
-- and that jest config is detected
local function ensure_test_environment()
	-- First, ensure project_nvim has set the correct cwd
	local ok, project = pcall(require, "project_nvim.project")
	if ok then
		project.on_buf_enter()
	end

	-- Then detect the nearest Jest config based on the current file path
	local file = vim.fn.expand("%:t")
	local file_dir = vim.fn.expand("%:p:h")
	local test_type = file:match("%.(%w+)%.test%.[jt]sx?$")
	local candidates = {
		"jest.config.ts",
		"jest.config.js",
		"jest.config.cjs",
		"jest.config.mjs",
	}

	if test_type then
		table.insert(candidates, 1, "jest.config." .. test_type .. ".ts")
		table.insert(candidates, 2, "jest.config." .. test_type .. ".js")
		table.insert(candidates, 3, "jest.config." .. test_type .. ".cjs")
		table.insert(candidates, 4, "jest.config." .. test_type .. ".mjs")
	end

	local project_root, config_file = find_nearest_file(file_dir, candidates)
	if project_root and config_file then
		vim.g["test#project_root"] = project_root
		vim.g["test#javascript#jest#options"] = "--config " .. config_file
		return
	end

	vim.g["test#project_root"] = nil
	vim.g["test#javascript#jest#options"] = ""
end

--------------------------------------------------------------------------------
-- ELIXIR
--------------------------------------------------------------------------------

local function elixir_test_file()
	local file = vim.fn.expand("%:s")
	local cmd = "mix test " .. file
	if has_mix_test_interactive() then
		cmd = "mix test.interactive " .. file
	end
	vim.cmd("TermExec direction=float cmd='" .. cmd .. "'")
end

local function elixir_test_line()
	local file = vim.fn.expand("%:s")
	local line = vim.fn.line(".")
	local cmd = "mix test " .. file .. ":" .. line
	if has_mix_test_interactive() then
		cmd = "mix test.interactive " .. file .. ":" .. line
	end
	vim.cmd("TermExec direction=float cmd='" .. cmd .. "'")
end

local function elixir_test_interactive()
	local cmd = "mix test"
	if has_mix_test_interactive() then
		cmd = "mix test.interactive"
	else
		vim.notify("mix test.interactive not found; using mix test", vim.log.levels.WARN)
	end
	vim.cmd("TermExec direction=float cmd='" .. cmd .. "'")
end

function M.test_file()
	ensure_test_environment()
	if is_elixir() then
		elixir_test_file()
	else
		vim.cmd("TestFile")
	end
end

function M.test_line()
	ensure_test_environment()
	if is_elixir() then
		elixir_test_line()
	else
		vim.cmd("TestNearest")
	end
end

function M.test_interactive()
	if is_elixir() then
		elixir_test_interactive()
	else
		-- vim-test doesn't have a watch mode, but we can use TestFile as fallback
		-- or notify the user
		vim.notify("Use <leader>ts or <leader>tf for non-Elixir files", vim.log.levels.INFO)
	end
end

function M.test_suite()
	vim.cmd("TestSuite")
end

function M.test_last()
	vim.cmd("TestLast")
end

function M.test_visit()
	vim.cmd("TestVisit")
end

return M
