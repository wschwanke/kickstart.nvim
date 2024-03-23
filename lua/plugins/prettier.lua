return {
  'prettier/vim-prettier',
  build = 'yarn install --frozen-lockfile --production',
  branch = 'master',
  config = function()
    -- Create or clear an autocommand group for prettier
    local prettier_group = vim.api.nvim_create_augroup('Prettier', { clear = true })

    -- Setup an autocommand to run PrettierFragment on buffer write for specific file types
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = prettier_group,
      pattern = { '*.js', '*.jsx', '*.ts', '*.tsx', '*.css', '*.scss' }, -- Specify your file patterns
      callback = function()
        vim.cmd 'PrettierFragment'
      end,
    })
  end,
}
