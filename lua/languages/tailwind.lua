return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        tailwindcss = {
          settings = {
            tailwindCSS = {
              classFunctions = {
                'classNames',
                'tw',
                'clsx',
                'cva',
              },
              classAttributes = {
                'className',
                'class',
              },
            },
          },
        },
      },
    },
  },
}
