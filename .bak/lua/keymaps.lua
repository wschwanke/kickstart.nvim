-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
vim.keymap.set('n', '<leader>b', vim.cmd.Ex, { desc = 'Open File [B]rowser (netrw)' })
-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit Terminal Mode' })

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move Block Down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move Block Up' })

vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join Lines (cursor stays)' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Half-Page Down (centered)' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Half-Page Up (centered)' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next Search Result (centered)' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Prev Search Result (centered)' })

vim.keymap.set('x', '<leader>p', [["_dP]], { desc = '[P]aste Over (keep register)' })

vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], { desc = '[Y]ank to System Clipboard' })
vim.keymap.set('n', '<leader>Y', [["+Y]], { desc = '[Y]ank Line to System Clipboard' })

vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]], { desc = '[D]elete to Black Hole' })
vim.keymap.set({ 'n', 'v' }, '<leader>c', [["_c]], { desc = '[C]hange to Black Hole' })
