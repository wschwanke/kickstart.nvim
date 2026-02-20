return {
  "folke/trouble.nvim",
  cmd = { "Trouble" },
  opts = {
    modes = {
      lsp = {
        win = { position = "right" },
      },
    },
  },
  keys = {
    { "<leader>ld", "<cmd>Trouble diagnostics toggle<cr>", desc = "LSP: [D]iagnostics (Trouble)" },
    {
      "<leader>lD",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "LSP: Buffer [D]iagnostics (Trouble)",
    },
    { "<leader>ls", "<cmd>Trouble symbols toggle<cr>", desc = "LSP: [S]ymbols (Trouble)" },
    {
      "<leader>lS",
      "<cmd>Trouble lsp toggle<cr>",
      desc = "LSP: [S]ymbols & References (Trouble)",
    },
    { "<leader>lq", "<cmd>Trouble qflist toggle<cr>", desc = "LSP: [Q]uickfix List (Trouble)" },
    { "<leader>ll", "<cmd>Trouble loclist toggle<cr>", desc = "LSP: [L]ocation List (Trouble)" },
    {
      "[q",
      function()
        if require("trouble").is_open() then
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = "Previous Trouble/Quickfix Item",
    },
    {
      "]q",
      function()
        if require("trouble").is_open() then
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = "Next Trouble/Quickfix Item",
    },
  },
}
