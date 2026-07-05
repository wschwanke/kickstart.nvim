return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        zls = {
          filetypes = { 'zig', 'zon' },
          -- Prefer the local zls build, fall back to zls on PATH
          cmd = (function()
            local local_zls = vim.fn.expand('~/apps/zls/zig-out/bin/zls')
            if vim.fn.executable(local_zls) == 1 then
              return { local_zls }
            end
            return { 'zls' }
          end)(),
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
