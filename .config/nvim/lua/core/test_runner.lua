local M = {}

local function is_elixir()
	return vim.bo.filetype == "elixir"
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
	if is_elixir() then
		elixir_test_file()
	else
		vim.cmd("TestFile")
	end
end

function M.test_line()
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
