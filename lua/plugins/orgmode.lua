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
        org_blank_before_new_entry = { heading = false, plain_list_item = false },
        org_default_notes_file = "~/.org/notes.org",
        org_archive_location = "~/.org/archive.org::",
        org_capture_templates = {
          t = { description = "Task", template = "* TODO %?\n  %u" },
        },
        org_startup_indented = true,
        org_adapt_indentation = false,
        mappings = {
          -- agenda/capture/note/edit_src/text_objects categories keep their
          -- defaults: they are buffer-local to special buffers and disabling
          -- them would break capture finalize/refile/kill and agenda navigation.
          global = {
            org_agenda = { "<leader>oa", desc = "Org: [A]genda" },
            org_capture = { "<leader>oc", desc = "Org: [C]apture" },
          },
          org = {
            -- TODO / headline editing
            org_todo = { "<leader>ot", desc = "Org: [T]odo Next State" },
            org_todo_prev = { "<leader>oT", desc = "Org: [T]odo Prev State" },
            org_priority = { "<leader>op", desc = "Org: Set [P]riority" },
            org_set_tags_command = { "<leader>oq", desc = "Org: Set Tags" },
            org_toggle_heading = { "<leader>oh", desc = "Org: Toggle [H]eadline" },
            org_move_subtree_up = { "<leader>oK", desc = "Org: Move Subtree Up" },
            org_move_subtree_down = { "<leader>oJ", desc = "Org: Move Subtree Down" },
            org_toggle_checkbox = { "<C-Space>", desc = "Org: Toggle Checkbox" },
            org_meta_return = { "<leader><CR>", "<C-CR>", desc = "Org: Meta Return (New Heading/Item)" },
            -- org_return = { "<CR>", desc = "Org: Smart Return" },
            org_return = false,
            org_cycle = { "<TAB>", desc = "Org: Cycle Fold" },
            org_global_cycle = { "<S-TAB>", desc = "Org: Cycle Fold (Global)" },
            org_do_promote = { "<<", desc = "Org: Promote Headline" },
            org_do_demote = { ">>", desc = "Org: Demote Headline" },
            org_promote_subtree = { "<s", desc = "Org: Promote Subtree" },
            org_demote_subtree = { ">s", desc = "Org: Demote Subtree" },
            -- headline motion
            org_next_visible_heading = { "}", desc = "Org: Next Heading" },
            org_previous_visible_heading = { "{", desc = "Org: Previous Heading" },
            org_forward_heading_same_level = { "]]", desc = "Org: Next Heading (Same Level)" },
            org_backward_heading_same_level = { "[[", desc = "Org: Previous Heading (Same Level)" },
            outline_up_heading = { "g{", desc = "Org: Parent Heading" },
            -- dates & scheduling
            org_schedule = { "<leader>ods", desc = "Org Date: [S]chedule" },
            org_deadline = { "<leader>odd", desc = "Org Date: [D]eadline" },
            org_time_stamp = { "<leader>odt", desc = "Org Date: Insert [T]imestamp" },
            org_time_stamp_inactive = { "<leader>odi", desc = "Org Date: [I]nactive Timestamp" },
            org_change_date = { "<leader>odc", desc = "Org Date: [C]hange Under Cursor" },
            org_timestamp_up = { "<C-a>", desc = "Org: Timestamp Up" },
            org_timestamp_down = { "<C-x>", desc = "Org: Timestamp Down" },
            org_timestamp_up_day = { "<S-UP>", desc = "Org: Timestamp Day Up" },
            org_timestamp_down_day = { "<S-DOWN>", desc = "Org: Timestamp Day Down" },
            org_priority_up = { "ciR", desc = "Org: Priority Up" },
            org_priority_down = { "cir", desc = "Org: Priority Down" },
            -- links & archive
            org_open_at_point = { "<leader>oo", desc = "Org: [O]pen Link / Follow" },
            org_store_link = { "<leader>oy", desc = "Org: Store Link ([Y]ank)" },
            org_archive_subtree = { "<leader>ox", desc = "Org: Archive Subtree" },
            org_toggle_archive_tag = { "<leader>oX", desc = "Org: Toggle ARCHIVE Tag" },
            org_show_help = { "g?", desc = "Org: Show Help" },
            -- export (needs emacs and/or pandoc on $PATH)
            -- NOTE: <leader>oe is taken by the Explore mapping below, so this is <leader>oE
            org_export = { "<leader>oE", desc = "Org: [E]xport" },
            -- everything else: explicitly disabled
            org_refile = false, -- replaced by telescope-orgmode <leader>or
            org_insert_link = false, -- replaced by telescope-orgmode <leader>ol
            org_edit_special = false,
            org_add_note = false,
            org_insert_heading_respect_content = false,
            org_insert_todo_heading = false,
            org_insert_todo_heading_respect_content = false,
            org_toggle_timestamp_type = false,
            org_clock_in = false,
            org_clock_out = false,
            org_clock_cancel = false,
            org_clock_goto = false,
            org_set_effort = false,
            org_babel_tangle = false,
          },
        },
      })

      -- Insert-mode meta return. The orgmode mappings table is normal-mode only
      -- (except org_return), so this has to be a buffer-local keymap.
      -- <S-CR> is included as a fallback: if the terminal stack swallows <C-CR>,
      -- Shift+Enter is the better-supported chord.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "org",
        callback = function()
          for _, key in ipairs({ "<C-CR>", "<S-CR>" }) do
            vim.keymap.set("i", key, '<cmd>lua require("orgmode").action("org_mappings.meta_return")<CR>', {
              silent = true,
              buffer = true,
              desc = "Org: Meta Return (New Heading/Item)",
            })
          end
        end,
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

      vim.keymap.set("n", "<leader>soh", tom.search_headings, { desc = "Search Org: [H]eadlines" })
      vim.keymap.set("n", "<leader>sot", tom.search_tags, { desc = "Search Org: [T]ags" })
      vim.keymap.set("n", "<leader>or", tom.refile_heading, { desc = "Org: [R]efile Heading" })
      vim.keymap.set("n", "<leader>ol", tom.insert_link, { desc = "Org: Insert [L]ink" })
      vim.keymap.set("n", "<leader>of", function()
        require("snacks").picker.files({ cwd = vim.fn.expand("~/.org") })
      end, { desc = "Org: [F]ind Files" })
      vim.keymap.set("n", "<leader>oe", function()
        vim.cmd.Explore(vim.fn.expand("~/.org"))
      end, { desc = "Org: [E]xplore Directory" })
    end,
  },
}
