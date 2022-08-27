local fn = vim.fn
local sep_style = vim.g.statusline_sep_style
local separators = (type(sep_style) == "table" and sep_style)
    or require("nvchad_ui.icons").statusline_separators[sep_style]
local sep_r = separators["right"]
local modes = {
  ["n"] = { "NORMAL", "St_NormalMode" },
  ["niI"] = { "NORMAL i", "St_NormalMode" },
  ["niR"] = { "NORMAL r", "St_NormalMode" },
  ["niV"] = { "NORMAL v", "St_NormalMode" },
  ["no"] = { "N-PENDING", "St_NormalMode" },
  ["i"] = { "INSERT", "St_InsertMode" },
  ["ic"] = { "INSERT (completion)", "St_InsertMode" },
  ["ix"] = { "INSERT completion", "St_InsertMode" },
  ["t"] = { "TERMINAL", "St_TerminalMode" },
  ["nt"] = { "NTERMINAL", "St_NTerminalMode" },
  ["v"] = { "VISUAL", "St_VisualMode" },
  ["V"] = { "V-LINE", "St_VisualMode" },
  ["Vs"] = { "V-LINE (Ctrl O)", "St_VisualMode" },
  [""] = { "V-BLOCK", "St_VisualMode" },
  ["R"] = { "REPLACE", "St_ReplaceMode" },
  ["Rv"] = { "V-REPLACE", "St_ReplaceMode" },
  ["s"] = { "SELECT", "St_SelectMode" },
  ["S"] = { "S-LINE", "St_SelectMode" },
  [""] = { "S-BLOCK", "St_SelectMode" },
  ["c"] = { "COMMAND", "St_CommandMode" },
  ["cv"] = { "COMMAND", "St_CommandMode" },
  ["ce"] = { "COMMAND", "St_CommandMode" },
  ["r"] = { "PROMPT", "St_ConfirmMode" },
  ["rm"] = { "MORE", "St_ConfirmMode" },
  ["r?"] = { "CONFIRM", "St_ConfirmMode" },
  ["!"] = { "SHELL", "St_TerminalMode" },
}

return {
  mode = function()
    local m = vim.api.nvim_get_mode().mode
    local current_mode = "%#" .. modes[m][2] .. "#" .. "  " .. modes[m][1]
    local mode_sep1 = "%#" .. modes[m][2] .. "Sep" .. "#" .. sep_r

    return current_mode .. mode_sep1 .. "%#ST_EmptySpace#" .. sep_r
  end,
  fileInfo = function()
    local icon = ""
    local root_dir = fn.fnamemodify(fn.getcwd(), ":t")
    local filename = ""
    if (fn.expand "%" == "") then
      icon = "   "
      filename = "Empty "
    elseif (string.find(fn.expand("%"), "NvimTree_")) then
      filename = root_dir
    else
      icon = "   "
      filename = (fn.expand "%" == "" and "Empty ") or
          (
          "%#St_file_root#" ..
              root_dir .. "%#St_file_path#" .. "/" .. fn.expand("%:.:h") .. "/" .. "%#St_file_name#" .. fn.expand("%:t")
          )
    end

    if filename ~= "Empty " then
      local devicons_present, devicons = pcall(require, "nvim-web-devicons")

      if devicons_present then
        local ft_icon = devicons.get_icon(filename)
        icon = (ft_icon ~= nil and " " .. ft_icon) or ""
      end

      filename = " " .. filename .. " "
    end

    return "%#St_file_info#" .. icon .. filename .. "%#St_file_sep#" .. sep_r
  end,
}
