return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = false, lsp_format = "fallback", timeout_ms = 10000 })
        end,
        mode = "",
        desc = "[F]ormat buffer",
      },
      {
        "<leader>F",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "x" },
        desc = "[F]ormat Injected Langs",
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = false,
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        cs = { "csharpier" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
        csharpier = {
          command = "csharpier",
          args = { "format", "--write-stdout" },
          stdin = true,
        },
      },
    },
  },
}
