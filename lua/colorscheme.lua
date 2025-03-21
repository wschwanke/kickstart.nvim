return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha',
        integrations = {
          cmp = true,
          fzf = true,
          treesitter = true,
          telescope = true,
          which_key = true,
          gitsigns = true,
          fidget = true,
        },
      }

      vim.cmd 'colorscheme catppuccin'
    end,
  },
  {
    'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = 'hard'
      vim.g.gruvbox_material_foreground = 'material'

      -- vim.cmd 'colorscheme gruvbox-material'
    end,
  },
  {
    'nyoom-engineering/oxocarbon.nvim',
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.opt.background = 'dark'
    end,
  },
}
