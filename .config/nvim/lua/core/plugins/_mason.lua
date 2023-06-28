local present, mason = pcall(require, "mason")

if not present then
  return
end

vim.api.nvim_create_augroup("_mason", { clear = true })
vim.api.nvim_create_autocmd("Filetype", {
  pattern = "mason",
  callback = function()
  end,
  group = "_mason",
})

local options = {
  ui = {
    icons = {
      package_pending = " ",
      package_installed = " ",
      package_uninstalled = " ﮊ",
    },
    keymaps = {
      toggle_server_expand = "<CR>",
      install_server = "i",
      update_server = "u",
      check_server_version = "c",
      update_all_servers = "U",
      check_outdated_servers = "C",
      uninstall_server = "X",
      cancel_installation = "<C-c>",
    },
  },
  max_concurrent_installers = 10,
}

-- LSP's to install with the MasonInstallAll auto cmd
local ensure_installed = {
  -- lua stuff
  "lua-language-server",
  "stylua",

  -- elixir
  "elixir-ls",
  "yamllint",
  "yaml-language-server",

  -- web dev
  "html-lsp",
  "css-lsp",
  "tailwindcss-language-server",
  "eslint-ls",
  "typescript-language-server",
  "json-lsp",

  -- shell
  "shfmt",
}

vim.api.nvim_create_user_command("MasonInstallAll", function()
  vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
end, {})

mason.setup(options)
