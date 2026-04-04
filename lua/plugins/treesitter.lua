return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  opts = {
    ensure_installed = {
      'bash',
      'html',
      'lua',
      'markdown',
      'jsdoc',
      'javascript',
      'typescript',
      'css',
      'scss',
      'go',
      'zig',
      'json',
      'python',
      'regex',
      'yaml',
      'sql',
      'graphql',
      'php',
      'razor',
      'c_sharp',
    },
    auto_install = true,
    highlight = {
      enable = true,
      use_languagetree = true,
    },
    indent = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<CR>',
        node_incremental = '<CR>',
        scope_incremental = false,
        node_decremental = '<BS>',
      },
    },
  },
  config = function(_, opts)
    ---@diagnostic disable-next-line: missing-fields
    require('nvim-treesitter.configs').setup(opts)
  end,
}
