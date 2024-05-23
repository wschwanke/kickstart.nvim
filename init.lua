-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require 'options'

require 'lazy_init'

require('lazy').setup({
  require 'lsp_config',

  require 'colorscheme',

  { import = 'plugins' },
}, {
  change_detection = {
    notify = false
  }
})

require 'snippets'

require 'keymaps'

require 'autocmds'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
