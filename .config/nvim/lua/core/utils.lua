local M = {}
local autocmd = vim.api.nvim_create_autocmd
local merge_table = vim.tbl_deep_extend

M.close_buffer = function(bufnr)
  if vim.bo.buftype == "terminal" then
    vim.cmd(vim.bo.buflisted and "set nobl | enew" or "hide")
  else
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    require("core.utils").tabuflinePrev()
    vim.cmd("confirm bd" .. bufnr)
  end
end

-- This must be used for plugins that need to be loaded just after a file
-- ex : treesitter, lspconfig etc
M.lazy_load = function(table)
  autocmd(table.events, {
    group = vim.api.nvim_create_augroup(table.augroup_name, {}),
    callback = function()
      if table.condition() then
        vim.api.nvim_del_augroup_by_name(table.augroup_name)

        -- dont defer for treesitter as it will show slow highlighting
        -- This deferring only happens when we do "nvim filename"
        if table.plugin ~= "nvim-treesitter" then
          vim.defer_fn(function()
            require("packer").loader(table.plugin)
            if table.plugin == "nvim-lspconfig" then
              vim.cmd "silent! do FileType"
            end
          end, 0)
        else
          require("packer").loader(table.plugin)
        end
      end
    end,
  })
end

-- load certain plugins only when there's a file opened in the buffer
-- if "nvim filename" is executed -> load the plugin after nvim gui loads
-- This gives an instant preview of nvim with the file opened
M.on_file_open = function(plugin_name)
  M.lazy_load {
    events = { "BufRead", "BufWinEnter", "BufNewFile" },
    augroup_name = "BeLazyOnFileOpen" .. plugin_name,
    plugin = plugin_name,
    condition = function()
      local file = vim.fn.expand "%"
      return file ~= "NvimTree_1" and file ~= "[packer]" and file ~= ""
    end,
  }
end

M.packer_cmds = {
  "PackerSnapshot",
  "PackerSnapshotRollback",
  "PackerSnapshotDelete",
  "PackerInstall",
  "PackerUpdate",
  "PackerSync",
  "PackerClean",
  "PackerCompile",
  "PackerStatus",
  "PackerProfile",
  "PackerLoad",
}

M.treesitter_cmds = {
  "TSInstall",
  "TSBufEnable",
  "TSBufDisable",
  "TSEnable",
  "TSDisable",
  "TSModuleInfo",
}

M.mason_cmds = {
  "Mason",
  "MasonInstall",
  "MasonInstallAll",
  "MasonUninstall",
  "MasonUninstallAll",
  "MasonLog",
}

M.gitsigns = function()
  autocmd({ "BufRead" }, {
    callback = function()
      vim.fn.system("git rev-parse " .. vim.fn.expand "%:p:h")
      if vim.v.shell_error == 0 then
        vim.schedule(function()
          require("packer").loader "gitsigns.nvim"
        end)
      end
    end,
  })
end

M.load_mappings = function(section, mapping_opt)
  -- My keymaps are loaded here, this allows for special config
  local mappings = require("core.keymaps")

  local function set_section_map(section_values)
    for mode, mode_values in pairs(section_values) do
      local default_opts = merge_table("force", { mode = mode }, mapping_opt or {})
      for keybind, mapping_info in pairs(mode_values) do
        -- merge default + user opts
        local opts = merge_table("force", default_opts, mapping_info.opts or {})

        mapping_info.opts, opts.mode = nil, nil
        opts.desc = mapping_info[2]

        vim.keymap.set(mode, keybind, mapping_info[1], opts)
      end
    end
  end

  if type(section) == "string" then
    mappings = { mappings[section] }
  end

  for _, sect in pairs(mappings) do
    set_section_map(sect)
  end
end

return M
