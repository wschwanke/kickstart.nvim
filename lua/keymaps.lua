-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
vim.keymap.set('n', '<leader>b', vim.cmd.Ex)
-- Set highlight on search, but clear on pressing <Esc> in normfal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Move block down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
-- Move block up
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- greatest remap ever
vim.keymap.set('x', '<leader>p', [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])
vim.keymap.set({ 'n', 'v' }, '<leader>c', [["_c]])

-- Create a variable to track the current state
local virtual_lines_enabled = false

-- Function to toggle between the two diagnostic configurations
local function toggle_diagnostic_display()
  virtual_lines_enabled = not virtual_lines_enabled

  if virtual_lines_enabled then
    -- Enable virtual_lines for current line
    vim.diagnostic.config {
      virtual_text = false,
      virtual_lines = true,
    }
    print 'Diagnostic: Virtual lines enabled'
  else
    -- Disable virtual_lines
    vim.diagnostic.config {
      virtual_text = true,
      virtual_lines = false,
    }
    print 'Diagnostic: Virtual lines disabled'
  end
end

vim.keymap.set('n', '<Leader>dl', toggle_diagnostic_display, { noremap = true, silent = false, desc = 'Toggle diagnostic virtual lines' })

-- You can change <Leader>td to any key combination you prefer
