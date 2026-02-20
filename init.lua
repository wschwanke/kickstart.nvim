--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require 'options'

require 'lazy_init'

require('lazy').setup({
  { import = 'lsp' },
  { import = 'plugins' },
  { import = 'languages' },
  { import = 'formatting' },
}, {
  change_detection = {
    notify = false,
  },
})

require 'keymaps'

require 'autocmds'
