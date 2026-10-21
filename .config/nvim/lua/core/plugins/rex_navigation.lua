local M = {}

function M.setup()
	if not vim.env.REX_SESSION or not vim.env.REX_BLOCK then
		return
	end

	for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
		vim.keymap.set("n", "<C-" .. key .. ">", function()
			local previous_window = vim.api.nvim_get_current_win()
			vim.cmd("wincmd " .. key)
			if vim.api.nvim_get_current_win() ~= previous_window then
				return
			end

			vim.system(
				{ "rex", "do", "navigate", "direction=" .. direction },
				{ text = true },
				vim.schedule_wrap(function(result)
					if result.code ~= 0 then
						vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR, { title = "Rex navigation" })
					end
				end)
			)
		end, { silent = true, desc = "Navigate " .. direction })
	end
end

return M
