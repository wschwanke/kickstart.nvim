return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { 'vim', 'it', 'describe', 'before_each', 'after_each' },
              },
            },
          },
        },
      },
    },
  },
}
