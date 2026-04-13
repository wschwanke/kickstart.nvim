return {
  -- {
  --   'catppuccin/nvim',
  --   name = 'catppuccin',
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require('catppuccin').setup {
  --       flavour = 'mocha',
  --       integrations = {
  --         blink_cmp = true,
  --         treesitter = true,
  --         telescope = true,
  --         which_key = true,
  --         gitsigns = true,
  --         fidget = true,
  --       },
  --     }
  --
  --     vim.cmd 'colorscheme catppuccin'
  --   end,
  -- },
  -- {
  --   "scottmckendry/cyberdream.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.cmd("colorscheme cyberdream")
  --   end,
  -- },
  -- {
  --   "oldjobobo/retro-82.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     transparent = false,
  --     terminal_colors = true,
  --   },
  --   config = function(_, opts)
  --     require("retro82").setup(opts)
  --     vim.cmd("colorscheme retro-82")
  --   end,
  -- },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "material"

      vim.cmd("colorscheme gruvbox-material")
    end,
  },
  -- {
  --   'nyoom-engineering/oxocarbon.nvim',
  --   lazy = false,
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     vim.opt.background = 'dark'
  --   end,
  -- },
}
