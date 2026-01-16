local M = {}

M.config = function()
	local harpoon = require("harpoon")

	harpoon:setup({
		settings = {
			save_on_toggle = true,
			sync_on_ui_close = true,
			key = function()
				local branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
				if branch ~= "" then
					return vim.loop.cwd() .. "-" .. branch
				end
				return vim.loop.cwd()
			end,
		},
	})

	local keymap = vim.keymap.set

	keymap("n", "<leader>m", function()
		harpoon.ui:toggle_quick_menu(harpoon:list())
	end, { desc = "Harpoon menu" })

	keymap("n", "<leader>M", function()
		harpoon:list():add()
	end, { desc = "Harpoon add file" })

	keymap("n", "<leader>h", function()
		harpoon:list():select(1)
	end, { desc = "Harpoon file 1" })

	keymap("n", "<leader>j", function()
		harpoon:list():select(2)
	end, { desc = "Harpoon file 2" })

	keymap("n", "<leader>k", function()
		harpoon:list():select(3)
	end, { desc = "Harpoon file 3" })

	keymap("n", "<leader>l", function()
		harpoon:list():select(4)
	end, { desc = "Harpoon file 4" })

	keymap("n", "<leader>[", function()
		harpoon:list():prev()
	end, { desc = "Harpoon prev" })

	keymap("n", "<leader>]", function()
		harpoon:list():next()
	end, { desc = "Harpoon next" })
end

return M
