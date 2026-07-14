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
      local tom = require("telescope-orgmode")
      tom.setup({ adapter = "snacks" })

      vim.keymap.set("n", "<leader>osh", tom.search_headings, { desc = "[O]rg Headlines" })
      vim.keymap.set("n", "<leader>ost", tom.search_tags, { desc = "[O]rg Tags" })
      vim.keymap.set("n", "<leader>or", tom.refile_heading, { desc = "[O]rg Refile" })
      vim.keymap.set("n", "<leader>oli", tom.insert_link, { desc = "[O]rg [L]ink [I]nsert" })
    end,
  },
}
