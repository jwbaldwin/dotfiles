local present, treesitter = pcall(require, "nvim-treesitter.configs")

if not present then
  return
end

local options = {
  ensure_installed = {
    "bash",
    "css",
    "eex",
    "elixir",
    "erlang",
    "heex",
    "html",
    "lua",
    "markdown",
    "markdown_inline",
    "norg",
    "tsx",
    "typescript",
    "yaml",
    "svelte"
  },
  highlight = {
    enable = true,
  },
}

treesitter.setup(options)
