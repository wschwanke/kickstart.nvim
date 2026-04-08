return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('nvim-treesitter-textobjects').setup({
      select = { lookahead = true },
      move = { set_jumps = true },
    })

    local sel = require('nvim-treesitter-textobjects.select')
    local move = require('nvim-treesitter-textobjects.move')
    local swap = require('nvim-treesitter-textobjects.swap')

    -- Select
    local select_maps = {
      ['af'] = '@function.outer',
      ['if'] = '@function.inner',
      ['ac'] = '@class.outer',
      ['ic'] = '@class.inner',
      ['aa'] = '@parameter.outer',
      ['ia'] = '@parameter.inner',
      ['ai'] = '@conditional.outer',
      ['ii'] = '@conditional.inner',
      ['al'] = '@loop.outer',
      ['il'] = '@loop.inner',
    }
    for key, query in pairs(select_maps) do
      vim.keymap.set({ 'x', 'o' }, key, function()
        sel.select_textobject(query, 'textobjects')
      end, { desc = query })
    end

    -- Move
    local move_maps = {
      [']f'] = { move.goto_next_start, '@function.outer' },
      ['[f'] = { move.goto_previous_start, '@function.outer' },
      [']F'] = { move.goto_next_end, '@function.outer' },
      ['[F'] = { move.goto_previous_end, '@function.outer' },
      [']a'] = { move.goto_next_start, '@parameter.outer' },
      ['[a'] = { move.goto_previous_start, '@parameter.outer' },
    }
    for key, val in pairs(move_maps) do
      vim.keymap.set({ 'n', 'x', 'o' }, key, function()
        val[1](val[2], 'textobjects')
      end, { desc = val[2] })
    end

    -- Swap
    vim.keymap.set('n', '<leader>na', function()
      swap.swap_next('@parameter.inner')
    end, { desc = 'Swap with Next Argument' })
    vim.keymap.set('n', '<leader>nA', function()
      swap.swap_previous('@parameter.inner')
    end, { desc = 'Swap with Previous Argument' })
  end,
}
