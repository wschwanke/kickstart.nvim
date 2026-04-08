return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup()

    -- Install parsers (replaces ensure_installed)
    local wanted = {
      'bash',
      'html',
      'lua',
      'markdown',
      'jsdoc',
      'ecma',
      'javascript',
      'typescript',
      'tsx',
      'jsx',
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
    }
    local installed = require('nvim-treesitter').get_installed()
    local missing = vim.tbl_filter(function(p)
      return not vim.tbl_contains(installed, p)
    end, wanted)
    if #missing > 0 then
      require('nvim-treesitter').install(missing)
    end

    -- Enable highlight + indent via autocmd (plugin no longer manages these)
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
