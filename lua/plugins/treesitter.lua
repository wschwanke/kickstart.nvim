return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  dependencies = {
    {
      'windwp/nvim-ts-autotag',
      opts = {},
    },
  },
  opts = {
    autotag = {
      enable = true,
      enable_rename = true,
      enable_close = true,
    },
    filesystem = {
      filtered_items = {
        visible = true,
      },
    },
    ensure_installed = {
      'bash',
      'c',
      'html',
      'lua',
      'markdown',
      'vim',
      'vimdoc',
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
      'php',
    },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
  },
  config = function(_, opts)
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    ---@class ParserInfo[]
    local parser_configs = require('nvim-treesitter.parsers').get_parser_configs()
    parser_configs.blade =
      {
        install_info = {
          url = 'https://github.com/EmranMR/tree-sitter-blade',
          files = { 'src/parser.c' },
          branch = 'main',
          generate_requires_npm = false,
          requires_generate_from_grammar = true,
        },
        filetype = 'blade',
      },
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup(opts)

    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  end,
}
