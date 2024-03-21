-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Define an autocmd group for the blade workaround
local augroup = vim.api.nvim_create_augroup('lsp_blade_workaround', { clear = true })

-- Autocommand to temporarily change 'blade' filetype to 'php' when opening for LSP server activation
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = augroup,
  pattern = '*.blade.php',
  callback = function()
    vim.bo.filetype = 'php'
  end,
})

-- Additional autocommand to switch back to 'blade' after LSP has attached
vim.api.nvim_create_autocmd('LspAttach', {
  pattern = '*.blade.php',
  callback = function(args)
    vim.schedule(function()
      -- Check if the attached client is 'intelephense'
      for _, client in ipairs(vim.lsp.get_active_clients()) do
        if client.name == 'intelephense' and client.attached_buffers[args.buf] then
          vim.api.nvim_buf_set_option(args.buf, 'filetype', 'blade')
          -- update treesitter parser to blade
          vim.api.nvim_buf_set_option(args.buf, 'syntax', 'blade')
          break
        end
      end
    end)
  end,
})
