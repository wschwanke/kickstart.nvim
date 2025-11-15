return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        zls = {
          filetypes = { 'zig', 'zon' },
          cmd = { '/home/wschwanke/apps/zls/zig-out/bin/zls' },
          settings = {
            zls = {
              semantic_tokens = 'partial',
            },
          },
        },
      },
      setup = {
        zls = function()
          vim.g.zig_fmt_autosave = 0
        end,
      },
    },
  },
}
