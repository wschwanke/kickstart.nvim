
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- `gleam lsp` and `gleam format` ship in the compiler; nothing to install.
        gleam = { mason = false },
      },
    },
  },
}
