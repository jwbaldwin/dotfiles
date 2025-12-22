local M = {}

local function is_elixir()
	return vim.bo.filetype == "elixir"
end

-- Ensure we're in the right directory before running tests (for monorepos)
-- and that jest config is detected
local function ensure_test_environment()
	-- First, ensure project_nvim has set the correct cwd
	local ok, project = pcall(require, "project_nvim.project")
	if ok then
		project.on_buf_enter()
	end

	-- Then detect jest config based on current file and cwd
	local file = vim.fn.expand("%:t")
	local test_type = file:match("%.(%w+)%.test%.[jt]sx?$")
	if test_type then
		local config_file = "jest.config." .. test_type .. ".ts"
		if vim.fn.filereadable(config_file) == 1 then
			vim.g["test#javascript#jest#options"] = "--config " .. config_file
			return
		end
	end
	if vim.fn.filereadable("jest.config.js") == 1 then
		vim.g["test#javascript#jest#options"] = "--config jest.config.js"
	else
		vim.g["test#javascript#jest#options"] = ""
	end
end

--------------------------------------------------------------------------------
-- ELIXIR
--------------------------------------------------------------------------------

local function elixir_test_file()
	local file = vim.fn.expand("%:s")
	local cmd = "mix test.interactive " .. file
	vim.cmd("TermExec direction=float cmd='" .. cmd .. "'")
end

local function elixir_test_line()
	local file = vim.fn.expand("%:s")
	local line = vim.fn.line(".")
	local cmd = "mix test.interactive " .. file .. ":" .. line
	vim.cmd("TermExec direction=float cmd='" .. cmd .. "'")
end

local function elixir_test_interactive()
	local cmd = "mix test.interactive"
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
