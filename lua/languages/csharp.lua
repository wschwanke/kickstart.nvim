return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        csharp_ls = {},
        omnisharp = {
          enabled = false,
        },
      },
    },
  },
}
