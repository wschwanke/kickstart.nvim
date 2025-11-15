return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        cssls = {
          settings = {
            css = {
              validate = false,
            },
          },
        },
      },
    },
  },
}
