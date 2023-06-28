local options = {
  style = "night",
  transparent = true,
  terminal_colors = true,
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    function_def = { italic = true },
    functions = {},
    variables = {},
    floats = "dark",
    sidebars = "dark",
  },
  sidebars = { "qf", "vista_kind", "terminal", "packer" },
  hide_inactive_statusline = true,
  lualine_bold = true,
  on_highlights = function(hl, c)
    local prompt = "#1f2335"
    hl.NvimTreeFolderIcon = { bg = c.none, fg = c.blue }
    hl.TelescopeNormal = {
      bg = c.bg_dark,
      fg = c.fg_dark,
    }
    hl.TelescopeBorder = {
      bg = c.bg_dark,
      fg = c.bg_dark,
    }
    hl.TelescopePromptNormal = {
      bg = prompt,
    }
    hl.TelescopePromptBorder = {
      bg = prompt,
      fg = prompt,
    }
    hl.TelescopePromptTitle = {
      bg = prompt,
      fg = prompt,
    }
    hl.TelescopePreviewTitle = {
      bg = c.bg_dark,
      fg = c.bg_dark,
    }
    hl.TelescopeResultsTitle = {
      bg = c.bg_dark,
      fg = c.bg_dark,
    }
  end,
}

require("tokyonight").setup(options)

vim.cmd [[colorscheme tokyonight]]
