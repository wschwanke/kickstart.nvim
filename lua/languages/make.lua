return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        autotools_ls = {},
      },
      tools = { "mbake", "checkmake" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        make = { "bake" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        make = { "checkmake" },
      },
    },
  },
}
