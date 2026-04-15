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
    end, { desc = 'Harpoon: [A]dd File' })
    vim.keymap.set('n', '<leader>hc', function()
      harpoon:list():clear()
    end, { desc = 'Harpoon: [C]lear List' })
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon: Quick Menu' })

    vim.keymap.set('n', '<leader>ha', function()
      harpoon:list():replace_at(1)
    end, { desc = 'Harpoon: Set Slot 1' })
    vim.keymap.set('n', '<leader>hs', function()
      harpoon:list():replace_at(2)
    end, { desc = 'Harpoon: Set Slot 2' })
    vim.keymap.set('n', '<leader>hd', function()
      harpoon:list():replace_at(3)
    end, { desc = 'Harpoon: Set Slot 3' })
    vim.keymap.set('n', '<leader>hf', function()
      harpoon:list():replace_at(4)
    end, { desc = 'Harpoon: Set Slot 4' })

    vim.keymap.set('n', '<C-S-P>', function()
      harpoon:list():prev()
    end, { desc = 'Harpoon: Previous File' })
    vim.keymap.set('n', '<C-S-N>', function()
      harpoon:list():next()
    end, { desc = 'Harpoon: Next File' })
  end,
}
