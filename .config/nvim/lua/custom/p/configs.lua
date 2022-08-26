local M = {}

M.treesitter = {
  ensure_installed = {
    "lua",
    "html",
    "css",
    "elixir",
    "eex",
    "erlang",
    "heex",
  },
}

M.nvimtree = {
  git = {
    enable = true,
  },
}

M.cmp = function()
  local cmp = require 'cmp'

  return {
    completion = {
      completeopt = "menu,menuone,noinsert",
    },
    mapping = {
      ["<C-j>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif require("luasnip").expand_or_jumpable() then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
        else
          fallback()
        end
      end, {
        "i",
        "s",
      }),
      ["<C-k>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif require("luasnip").jumpable(-1) then
          vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
        else
          fallback()
        end
      end, {
        "i",
        "s",
      }),
    }
  }
end

M.ui = {
  statusline = {
    separator_style = "round",
  },
}

return M
