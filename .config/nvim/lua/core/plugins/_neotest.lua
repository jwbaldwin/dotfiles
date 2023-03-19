local neotest = require("neotest")

neotest.setup({
  adapters = {
    require("neotest-vim-test")({ allow_file_types = { "elixir" } }),
    require("neotest-elixir"),
  }
})
