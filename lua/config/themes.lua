return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    opts = {
      flavour = 'mocha',
      integrations = {
        blink_cmp = true,
        treesitter = true,
        telescope = true,
        which_key = true,
        gitsigns = true,
        fidget = true,
      },
    },
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "oldjobobo/retro-82.nvim",
    lazy = false,
    priority = 1000,
    main = "retro82",
    opts = {
      transparent = false,
      terminal_colors = true,
    },
  },
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.gruvbox_material_background = "hard"
      vim.g.gruvbox_material_foreground = "material"
    end,
  },
  {
    'nyoom-engineering/oxocarbon.nvim',
    lazy = false,
    priority = 1000,
  },
}
