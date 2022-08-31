local italic = { italic = true }
local M = {}

M.tokyostorm = {
  override = {
    TSNote = italic,
    TSComment = italic,
    TSKeyword = italic,
    TSKeywordFunction = italic,
    Comment = italic,
    SpecialComment = italic,
    Keyword = italic,
  },
  add = {}
}

M.moonlight = {
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
    NormalFloat = { bg = "black" },
    TelescopeSelection = { bg = "pmenu_bg" },
    Type = { fg = "yellow" },
    TSSymbol = { fg = "baby_pink" },
    Label = { fg = "sun" },
    Search = { fg = "base01", bg = "base0A" }, -- regex search like :%s/<>/<>/g idk what to do here
    CursorLine = { bg = "black" },
    DiffAdd = { fg = "green" },
    DiffAdded = { fg = "cyan" },
    DiffChange = { fg = "blue" }
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
    },
  }
}

return M
