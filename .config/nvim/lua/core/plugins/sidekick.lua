local M = {}

local function send_opencode_input(terminal)
	terminal.timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			local input = table.remove(terminal.send_queue, 1)
			if not input or not terminal:is_running() then
				return
			end
			input = input:gsub("\r\n", "\n")
			-- OpenCode V2 treats a pasted carriage return as text, not a submit key
			if input == "\r" then
				vim.api.nvim_chan_send(terminal.job, input)
			else
				vim.api.nvim_buf_call(terminal.buf, function()
					vim.api.nvim_put(vim.split(input, "\n", { plain = true }), "c", false, true)
				end)
			end
			if terminal:is_focused() then
				vim.cmd.startinsert()
			end
		end)
	)
end

M.opts = {
	nes = { enabled = false },
	copilot = { status = { enabled = false } },
	cli = {
		win = {
			config = function(terminal)
				if terminal.tool.name == "selection_edit" then
					terminal.on_ready = send_opencode_input
				end
			end,
		},
		tools = {
			selection_edit = {
				cmd = { "opencode", "--standalone" },
				env = {
					OPENCODE_CONFIG_CONTENT = vim.json.encode({
						model = "openai/gpt-6-astra",
						providers = {
							openai = {
								models = {
									["gpt-6-astra"] = {
										settings = { reasoningEffort = "medium", serviceTier = "priority" },
									},
								},
							},
						},
					}),
				},
			},
		},
	},
}

function M.edit_selection()
	local buffer = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(buffer)
	if filename == "" or vim.bo[buffer].buftype ~= "" then
		vim.notify("Give this buffer a file name before requesting an edit", vim.log.levels.WARN)
		return
	end

	local selection_start = vim.fn.getpos("v")
	local selection_end = vim.fn.getpos(".")
	local selection = vim.fn.getregion(selection_start, selection_end, {
		type = vim.fn.mode(),
		exclusive = vim.o.selection == "exclusive",
	})
	local first_line = math.min(selection_start[2], selection_end[2])
	local last_line = math.max(selection_start[2], selection_end[2])

	vim.ui.input({ prompt = "Edit selection: " }, function(instruction)
		if not instruction or vim.trim(instruction) == "" then
			return
		end

		local saved, err = pcall(vim.api.nvim_buf_call, buffer, function()
			vim.cmd.update()
		end)
		if not saved then
			vim.notify(tostring(err), vim.log.levels.ERROR)
			return
		end

		local text = {
			{ { "Edit only the selected code in " .. filename .. ". Keep unrelated code unchanged." } },
			{ { ("Selection originally at lines %d-%d."):format(first_line, last_line) } },
			{ { "The file was saved after capturing this selection; account for any format-on-save changes." } },
			{ { "Apply the change to the file, rather than only describing it." } },
			{ { "Instruction: " .. instruction } },
			{ { "Selected code:" } },
		}
		for _, line in ipairs(selection) do
			text[#text + 1] = { { line } }
		end
		require("sidekick.cli").send({ name = "selection_edit", text = text, submit = true, focus = false })
	end)
end

return M
