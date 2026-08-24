-- docgen: LLM-generated doc comments (JSDoc / @doc / Odin / LuaCATS) via OpenRouter. Replaces neogen.
-- Implementation lives in lua/utils/docgen/ (TeamoXtremo.util.docgen).
return {
  {
    -- A real, unique dir: lazy.nvim dedupes plugins by directory, so `dir = "."` would get
    -- merged into any other `dir = "."` spec (e.g. uuid.lua) and the two configs would clobber each other.
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "utils", "docgen"),
    name = "docgen",
    cmd = { "DocGen", "DocModel", "DocGenCancel" },
    keys = {
      {
        "<leader>ln",
        function()
          require("utils.docgen").generate({ levels = vim.v.count })
        end,
        desc = "LSP: Generate A[n]notations",
      },
    },
    ---@type docgen.Config
    opts = {},
    config = function(_, opts)
      local docgen = require("utils.docgen")
      docgen.setup(opts)

      vim.api.nvim_create_user_command("DocGen", function(a)
        docgen.generate({ levels = a.count > 0 and a.count or 0 })
      end, { count = 0, desc = "docgen: document the function under the cursor ([count] walks outward)" })

      vim.api.nvim_create_user_command("DocModel", function(a)
        docgen.select_model({ refresh = a.bang })
      end, { bang = true, desc = "docgen: pick the OpenRouter model (! refreshes the list)" })

      vim.api.nvim_create_user_command("DocGenCancel", function()
        docgen.cancel()
      end, { desc = "docgen: cancel in-flight requests" })
    end,
  },
}
