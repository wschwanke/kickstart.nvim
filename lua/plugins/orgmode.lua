return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    dependencies = {
      "akinsho/org-bullets.nvim",
    },
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/orgfiles/**/*",
        org_default_notes_file = "~/orgfiles/refile.org",
      })

      vim.lsp.enable("org")
    end,
  },
  {
    "nvim-orgmode/org-bullets.nvim",
    config = function()
      require("org-bullets").setup()
    end,
  },
  {
    "nvim-orgmode/telescope-orgmode.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("orgmode")

      local ext = require("telescope").extensions.orgmode
      vim.keymap.set("n", "<leader>sh", ext.search_headings, { desc = "Org headlines" })
      vim.keymap.set("n", "<leader>st", ext.search_tags, { desc = "Org tags" })
      -- vim.keymap.set("n", "<leader>r", ext.refile_heading, { desc = "Org refile" })
      -- vim.keymap.set("n", "<leader>li", ext.insert_link, { desc = "Org insert link" })
    end,
  },
}
