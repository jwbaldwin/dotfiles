require("core.options")
require("core.plugins")

require("core.utils").load_mappings()
require("core.highlights").setup()

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. vim.fn.stdpath("data") .. "/mason/bin"

-- dont list quickfix buffers
vim.api.nvim_create_autocmd("FileType", {
	pattern = "qf",
	callback = function()
		vim.opt_local.buflisted = false
	end,
})
