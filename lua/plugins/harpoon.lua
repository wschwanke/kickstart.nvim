return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- REQUIRED
    harpoon:setup {}
    -- REQUIRED

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'Harpoon [A]dd' })
    vim.keymap.set('n', '<leader>hc', function()
      harpoon:list():clear()
    end)
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():replace_at(1)
    end)
    vim.keymap.set('n', '<leader>hs', function()
      harpoon:list():replace_at(1)
    end)
    vim.keymap.set('n', '<leader>hd', function()
      harpoon:list():replace_at(1)
    end)
    vim.keymap.set('n', '<leader>hf', function()
      harpoon:list():replace_at(1)
    end)

    vim.keymap.set('n', '<C-a>', function()
      harpoon:list():select(1)
    end)
    vim.keymap.set('n', '<C-s>', function()
      harpoon:list():select(2)
    end)
    vim.keymap.set('n', '<C-d>', function()
      harpoon:list():select(3)
    end)
    vim.keymap.set('n', '<C-f>', function()
      harpoon:list():select(4)
    end)

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<C-S-P>', function()
      harpoon:list():prev()
    end)
    vim.keymap.set('n', '<C-S-N>', function()
      harpoon:list():next()
    end)
  end,
}
