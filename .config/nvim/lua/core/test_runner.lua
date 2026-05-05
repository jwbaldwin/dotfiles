local M = {}

local function is_elixir()
	return vim.bo.filetype == "elixir"
end

local function has_mix_test_interactive()
	vim.fn.system({ "mix", "help", "test.interactive" })
	return vim.v.shell_error == 0
end

local function find_package_json(file)
	return vim.fs.find("package.json", { path = vim.fs.dirname(file), upward = true })[1]
end

local function read_json_file(file)
	local lines = vim.fn.readfile(file)
	if vim.v.shell_error ~= 0 then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	return ok and decoded or nil
end

local function package_has_dependency(package_json, name)
	local dependencies = package_json.dependencies or {}
	local dev_dependencies = package_json.devDependencies or {}
	return dependencies[name] ~= nil or dev_dependencies[name] ~= nil
end

local function file_contains(file, pattern)
	local lines = vim.fn.readfile(file)
	for _, line in ipairs(lines) do
		if line:find(pattern, 1, true) then
			return true
		end
	end

	return false
end

local function detect_javascript_runner(file)
	local package_json_path = find_package_json(file)
	if not package_json_path then
		return nil
	end

	local package_json = read_json_file(package_json_path)
	if not package_json then
		return nil
	end

	local has_jest = package_has_dependency(package_json, "jest")
	local has_vitest = package_has_dependency(package_json, "vitest")
	local has_playwright = package_has_dependency(package_json, "@playwright/test")

	if file_contains(file, "@playwright/test") or (has_playwright and (file:find("/playwright/", 1, true) or file:match("%.spec%.[jt]sx?$"))) then
		return "playwright"
	end

	if file_contains(file, "vitest") then
		return "vitest"
	end

	if has_jest then
		return "jest"
	end

	if has_vitest then
		return "vitest"
	end

	if has_playwright then
		return "playwright"
	end

	return nil
end

local function set_test_context()
	local file = vim.fn.expand("%:p")
	local runner = detect_javascript_runner(file)

	vim.fn.setenv("NVIM_TEST_FILE", file)
	vim.fn.setenv("NVIM_TEST_RUNNER", runner or "")
	vim.g["test#javascript#runner"] = runner
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
	if is_elixir() then
		elixir_test_file()
	else
		set_test_context()
		vim.cmd("TestFile")
	end
end

function M.test_line()
	if is_elixir() then
		elixir_test_line()
	else
		set_test_context()
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
	set_test_context()
	vim.cmd("TestSuite")
end

function M.test_last()
	set_test_context()
	vim.cmd("TestLast")
end

function M.test_visit()
	vim.cmd("TestVisit")
end

return M
