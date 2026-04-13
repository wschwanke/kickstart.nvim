return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    max_lines = 3,
    min_window_height = 20,
    trim_scope = "outer",
  },
  keys = {
    {
      "[c",
      function()
        require("treesitter-context").go_to_context(vim.v.count1)
      end,
      desc = "Jump to Context",
    },
  },
}
