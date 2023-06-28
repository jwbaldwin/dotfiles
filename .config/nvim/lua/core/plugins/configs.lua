local M = {}

M.notify = function()
  local present, notify = pcall(require, "nvim-notify")

  if not present then
    return
  end
  notify.setup({

  })
end

M.todo = function()
  local present, todo = pcall(require, "todo-comments")

  if not present then
    return
  end

  todo.setup()
end

M.persisted = function()
  local present, persisted = pcall(require, "persisted")

  if not present then
    return
  end

  local options = {
    save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"), -- directory where session files are saved
    command = "VimLeavePre",                                          -- the autocommand for which the session is saved
    silent = false,                                                   -- silent nvim message when sourcing session file
    use_git_branch = true,                                            -- create session files based on the branch of the git enabled repository
    branch_separator = "_",                                           -- string used to separate session directory name from branch name
    autosave = true,                                                  -- automatically save session files when exiting Neovim
    autoload = false,                                                 -- automatically load the session for the cwd on Neovim startup
    on_autoload_no_session = nil,                                     -- function to run when `autoload = true` but there is no session to load
    allowed_dirs = nil,                                               -- table of dirs that the plugin will auto-save and auto-load from
    ignored_dirs = nil,                                               -- table of dirs that are ignored when auto-saving and auto-loading
    before_save = nil,                                                -- function to run before the session is saved to disk
    after_save = nil,                                                 -- function to run after the session is saved to disk
    after_source = nil,                                               -- function to run after the session is sourced
    telescope = {                                                     -- options for the telescope extension
      before_source = nil,                                            -- function to run before the session is sourced via telescope
      after_source = nil,                                             -- function to run after the session is sourced via telescope
    },
  }

  persisted.setup(options)
end

M.harpoon = function()
  local present, harpoon = pcall(require, "harpoon")

  if not present then
    return
  end

  local options = {
    global_settings = {
      -- set marks specific to each git branch inside git repository
      mark_branch = true,
    }
  }

  harpoon.setup(options)
end

M.gitsigns = function()
  local present, gitsigns = pcall(require, "gitsigns")

  if not present then
    return
  end

  local options = {
    -- signs = {
    --   add = { hl = "DiffAdd", text = "│", numhl = "GitSignsAddNr" },
    --   change = { hl = "DiffChange", text = "│", numhl = "GitSignsChangeNr" },
    -- },
  }

  gitsigns.setup(options)
end

M.autopairs = function()
  local present1, autopairs = pcall(require, "nvim-autopairs")
  local present2, cmp = pcall(require, "cmp")

  if not (present1 and present2) then
    return
  end

  local options = {
    fast_wrap = {},
    disable_filetype = { "TelescopePrompt", "vim" },
  }

  autopairs.setup(options)

  local cmp_autopairs = require "nvim-autopairs.completion.cmp"
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

M.blankline = function()
  local present, blankline = pcall(require, "indent_blankline")

  if not present then
    return
  end

  local options = {
    indentLine_enabled = 1,
    filetype_exclude = {
      "help",
      "terminal",
      "alpha",
      "lspinfo",
      "TelescopePrompt",
      "TelescopeResults",
      "mason",
      "",
    },
    buftype_exclude = { "terminal" },
    show_trailing_blankline_indent = false,
    show_first_indent_level = false,
    show_current_context = true,
    show_current_context_start = false,
  }

  blankline.setup(options)
end

M.comment = function()
  local present, nvim_comment = pcall(require, "Comment")

  if not present then
    return
  end

  local options = {}
  nvim_comment.setup(options)
end

M.luasnip = function()
  local present, luasnip = pcall(require, "luasnip")

  if not present then
    return
  end

  local options = {
    history = true,
    updateevents = "TextChanged,TextChangedI",
  }

  luasnip.config.set_config(options)

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      if require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
          and not require("luasnip").session.jump_active
      then
        require("luasnip").unlink_current()
      end
    end,
  })
end

M.devicons = function()
  local present, devicons = pcall(require, "nvim-web-devicons")

  if present then
    -- local options = { override = require("core.icons").devicons }
    local options = {}

    devicons.setup(options)
  end
end

return M
