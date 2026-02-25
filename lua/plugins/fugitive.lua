return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = 'Git: [S]tatus (Fugitive)' })
    vim.keymap.set('n', '<leader>gd', '<cmd>Gvdiffsplit<cr>', { desc = 'Git: [D]iff Split' })
    vim.keymap.set('n', '<leader>gl', '<cmd>Git log --oneline<cr>', { desc = 'Git: [L]og' })
    vim.keymap.set('n', '<leader>gp', '<cmd>Git push<cr>', { desc = 'Git: [P]ush' })
    vim.keymap.set('n', '<leader>gP', '<cmd>Git pull<cr>', { desc = 'Git: [P]ull' })
  end,
}
