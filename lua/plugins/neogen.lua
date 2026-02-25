return {
  "danymat/neogen",
  cmd = "Neogen",
  keys = {
    {
      "<leader>ln",
      function()
        require("neogen").generate()
      end,
      desc = "LSP: Generate A[n]notations (Neogen)",
    },
  },
  opts = {},
}
