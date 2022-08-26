local fn = vim.fn
local sep_style = vim.g.statusline_sep_style
local separators = (type(sep_style) == "table" and sep_style)
    or require("nvchad_ui.icons").statusline_separators[sep_style]
local sep_r = separators["right"]

return {
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
