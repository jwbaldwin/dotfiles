local alpha = require "alpha"

local function button(sc, txt, keybind)
  local sc_ = sc:gsub("%s", ""):gsub("SPC", "<leader>")

  local opts = {
    position = "center",
    text = txt,
    shortcut = sc,
    cursor = 5,
    width = 24,
    align_shortcut = "right",
    hl_shortcut = "Number",
    hl = "AlphaButton",
  }

  if keybind then
    opts.keymap = { "n", sc_, keybind, { noremap = true, silent = true } }
  end

  return {
    type = "button",
    val = txt,
    on_press = function()
      local key = vim.api.nvim_replace_termcodes(sc_, true, false, true) or ""
      vim.api.nvim_feedkeys(key, "normal", false)
    end,
    opts = opts,
  }
end

-- dynamic header padding
local fn = vim.fn
local marginTopPercent = 0.15
local headerPadding = fn.max { 2, fn.floor(fn.winheight(0) * marginTopPercent) }

local options = {
  header = {
    type = "text",
    val = {
      [[                                   /\                                ]],
      [[                              /\  //\\                               ]],
      [[                       /\    //\\///\\\        /\                    ]],
      [[                      //\\  ///\////\\\\  /\  //\\                   ]],
      [[         /\          /  ^ \/^ ^/^  ^  ^ \/^ \/  ^ \                  ]],
      [[        / ^\    /\  / ^   /  ^/ ^ ^ ^   ^\ ^/  ^^  \                 ]],
      [[       /^   \  / ^\/ ^ ^   ^ / ^  ^    ^  \/ ^   ^  \       *        ]],
      [[      /  ^ ^ \/^  ^\ ^ ^ ^   ^  ^   ^   ____  ^   ^  \     /|\       ]],
      [[     / ^ ^  ^ \ ^  _\___________________|  |_____^ ^  \   /||o\      ]],
      [[    / ^^  ^ ^ ^\  /______________________________\ ^ ^ \ /|o|||\     ]],
      [[   /  ^  ^^ ^ ^  /________________________________\  ^  /|||||o|\    ]],
      [[  /^ ^  ^ ^^  ^    ||___|___||||||||||||___|__|||      /||o||||||\   ]],
      [[ / ^   ^   ^    ^  ||___|___||||||||||||___|__|||          | |       ]],
      [[/ ^ ^ ^  ^  ^  ^   ||||||||||||||||||||||||||||||oooooooooo| |ooooooo]],
      [[ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],
      [[]],
    },
    opts = {
      position = "center",
      hl = "Comment",
    },
  },

  buttons = {
    type = "group",
    val = {
      button("f", "  Find File  ", ":Telescope find_files<CR>"),
      button("p", "  Projects", ":Telescope projects<CR>"),
      button("r", "  Recents", ":Telescope oldfiles<CR>"),
      button("s", "  Restore", ":Telescope persisted<CR>"),
      button("c", "  Settings", ":e ~/.config/nvim/init.lua | :cd %:p:h <CR>"),
    },
    opts = {
      spacing = 1,
    },
  },

  headerPaddingTop = { type = "padding", val = headerPadding },
  headerPaddingBottom = { type = "padding", val = 2 },
}

alpha.setup {
  layout = {
    options.headerPaddingTop,
    options.header,
    options.headerPaddingBottom,
    options.buttons,
  },
  opts = {},
}

-- Disable statusline in dashboard
vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function()
    -- store current statusline value and use that
    local old_laststatus = vim.opt.laststatus
    vim.api.nvim_create_autocmd("BufUnload", {
      buffer = 0,
      callback = function()
        vim.opt.laststatus = old_laststatus
      end,
    })
    vim.opt.laststatus = 0
  end,
})