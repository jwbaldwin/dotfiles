--
-- load my globals, autocmds here or anything
--

vim.opt.laststatus = 3 -- global statusline
vim.opt.showmode = false

vim.opt.title = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.winborder = "none"

vim.opt.backup = false
vim.opt.writebackup = false

-- Indenting
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.fillchars = { eob = " " }
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"
vim.opt.filetype = "on"

-- Numbers
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.numberwidth = 2
vim.opt.ruler = false

-- disable nvim intro
vim.opt.shortmess:append("sI")

vim.opt.signcolumn = "yes"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.timeoutlen = 400
vim.opt.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
vim.opt.updatetime = 250
vim.opt.swapfile = false

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
vim.opt.whichwrap:append("<>[]hl")

vim.opt.completeopt = "menuone,noselect"

vim.g.vim_version = vim.version().minor
if vim.g.vim_version < 8 then
	vim.g.did_load_filetypes = 0
	vim.g.do_filetype_lua = 1
end
vim.g.mapleader = " "
vim.o.background = "dark"

-- formatter.nvim autoformat on save
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
augroup("__formatter__", { clear = true })
autocmd("BufWritePost", {
	group = "__formatter__",
	command = ":FormatWrite",
})

-- vim test setup
vim.g["test#strategy"] = "neovim"
vim.g["test#neovim#start_normal"] = 1 -- start in normal mode
vim.g["test#neovim#term_position"] = "vert" -- split right
vim.g["test#echo_command"] = 1 -- echo the command

-- Copilot setup
vim.g.copilot_no_tab_map = true
vim.g.copilot_enabled = true

-- disable some builtin vim plugins
local default_plugins = {
	"2html_plugin",
	"getscript",
	"getscriptPlugin",
	"gzip",
	"logipat",
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
	"matchit",
	"tar",
	"tarPlugin",
	"rrhelper",
	"spellfile_plugin",
	"vimball",
	"vimballPlugin",
	"zip",
	"zipPlugin",
	"tutor",
	"rplugin",
	"syntax",
	"synmenu",
	"optwin",
	"compiler",
	"bugreport",
	"ftplugin",
}

for _, plugin in pairs(default_plugins) do
	vim.g["loaded_" .. plugin] = 1
end

local default_providers = {
	"node",
	"perl",
	"python3",
	"ruby",
}

for _, provider in ipairs(default_providers) do
	vim.g["loaded_" .. provider .. "_provider"] = 0
end
