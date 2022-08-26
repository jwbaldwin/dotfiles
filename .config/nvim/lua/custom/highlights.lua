local italic = { italic = true }

return {
  override = {
    TSNote = italic,
    TSComment = italic,
    TSKeyword = italic,
    TSKeywordFunction = italic,
    Comment = italic,
    SpecialComment = italic,
    Keyword = italic,
    Constant = { fg = "orange" },
    Special = { fg = "blue", bold = true },
    PmenuSel = { bg = "pmenu_bg", fg = "white" },
    NormalFloat = { bg = "one_bg" },
    TelescopeSelection = { bg = "pmenu_bg" },
  },
  add = {
    St_file_root = {
      bold = true,
      bg = "lightbg",
      fg = "teal"
    },
    St_file_path = {
      bg = "lightbg",
      fg = "grey_fg2"
    },
    St_file_name = {
      bg = "lightbg",
      fg = "white"
    }
  }
}
