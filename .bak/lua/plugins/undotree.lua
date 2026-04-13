return {
  'mbbill/undotree',
  config = function()
    vim.keymap.set('n', '<leader>ut', vim.cmd.UndotreeToggle, { desc = 'Undotree: [T]oggle' })
    vim.keymap.set('n', '<leader>uf', vim.cmd.UndotreeFocus, { desc = 'Undotree: [F]ocus' })
  end,
}
