-- UUID generator: <leader>gu in normal/insert mode to insert a UUID v4
return {
  {
    dir = '.',
    name = 'uuid-generator',
    config = function()
      local function insert_uuid()
        local id = vim.fn.system('uuidgen'):gsub('%s+', '')
        vim.api.nvim_put({ id }, 'c', false, true)
      end

      vim.keymap.set('n', '<leader>gu', insert_uuid, { desc = '[G]enerate [U]UID v4' })
      vim.keymap.set('i', '<C-g>', insert_uuid, { desc = 'Insert UUID v4' })
    end,
  },
}
