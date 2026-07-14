return {
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        -- Load snacks.nvim types when the `Snacks` global is found
        { path = 'snacks.nvim', words = { 'Snacks' } },
        -- Load lazy.nvim types when the `LazySpec` annotation is found
        { path = 'lazy.nvim', words = { 'LazySpec' } },
      },
    },
  },
}
