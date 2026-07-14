return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    dependencies = {
      "akinsho/org-bullets.nvim",
    },
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_todo_keywords = { "TODO(t)", "NEXT(n)", "WAITING(w)", "|", "DONE(d)", "CANCELLED(c)" },
        org_agenda_files = "~/.org/**/*",
        org_default_notes_file = "~/.org/notes.org",
        org_archive_location = "~/.org/archive.org",
        org_capture_templates = {
          t = { description = "Task", template = "* TODO %?\n  %u" },
        },
        org_startup_indented = true,
        org_adapt_indentation = false,
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

      vim.keymap.set("n", "<leader>soh", tom.search_headings, { desc = "[O]rg Headlines" })
      vim.keymap.set("n", "<leader>sot", tom.search_tags, { desc = "[O]rg Tags" })
      vim.keymap.set("n", "<leader>or", tom.refile_heading, { desc = "[O]rg Refile" })
      vim.keymap.set("n", "<leader>ol", tom.insert_link, { desc = "[O]rg [L]ink [I]nsert" })
      vim.keymap.set("n", "<leader>of", function()
        require("snacks").picker.files({ cwd = vim.fn.expand("~/.org") })
      end, { desc = "[O]rg [F]iles" })
      vim.keymap.set("n", "<leader>oe", function()
        vim.cmd.Explore(vim.fn.expand("~/.org"))
      end, { desc = "[O]rg [E]xplore" })
    end,
  },
}
