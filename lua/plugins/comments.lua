return {
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {
      lang = {
        odin = { "// %s", "/*\n\t%s\n*/" },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      {
        "<leader>st",
        function()
          ---@diagnostic disable-next-line: undefined-field
          Snacks.picker.todo_comments()
        end,
        desc = "Search: [T]odo Comments",
      },
      {
        "<leader>sT",
        function()
          ---@diagnostic disable-next-line: undefined-field
          Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
        end,
        desc = "Search: [T]odo/Fix/Fixme",
      },
    },
  },
}
