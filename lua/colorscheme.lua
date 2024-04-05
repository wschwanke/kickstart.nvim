return {
  -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command in the config to whatever the name of that colorscheme is
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`
  'projekt0n/github-nvim-theme',
  lazy = false,
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    vim.cmd 'colorscheme github_dark_default'
  end,
}
