return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup()

    -- Install parsers (replaces ensure_installed)
    local wanted = {
      'bash',
      'html',
      'lua',
      'markdown',
      'jsdoc',
      'ecma',
      'javascript',
      'typescript',
      'tsx',
      'jsx',
      'css',
      'scss',
      'go',
      'zig',
      'json',
      'python',
      'regex',
      'yaml',
      'sql',
      'graphql',
      'php',
      'razor',
      'c_sharp',
    }
    local installed = require('nvim-treesitter').get_installed()
    local missing = vim.tbl_filter(function(p)
      return not vim.tbl_contains(installed, p)
    end, wanted)
    if #missing > 0 then
      require('nvim-treesitter').install(missing)
    end

    -- Enable highlight + indent via autocmd (plugin no longer manages these)
    local elixir_fts = { elixir = true, eelixir = true, heex = true }
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
        if elixir_fts[vim.bo.filetype] then
          vim.bo.indentexpr = "v:lua.require'indent.elixir'.get_indent(v:lnum)"
          vim.bo.indentkeys = "0{,0},0],0),!^F,o,O,=end,=else,=rescue,=after,=catch"
        else
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    -- Incremental selection (ported from old config)
    local node_stack = {}
    vim.keymap.set('n', '<CR>', function()
      local node = vim.treesitter.get_node()
      if not node then return end
      node_stack = { node }
      local sr, sc, er, ec = node:range()
      vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
      vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
      vim.cmd('normal! gv')
    end, { desc = 'Init treesitter selection' })

    vim.keymap.set('x', '<CR>', function()
      local current = node_stack[#node_stack]
      if not current then return end
      local parent = current:parent()
      if not parent then return end
      table.insert(node_stack, parent)
      local sr, sc, er, ec = parent:range()
      vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
      vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
      vim.cmd('normal! gv')
    end, { desc = 'Increment treesitter selection' })

    vim.keymap.set('x', '<BS>', function()
      if #node_stack <= 1 then return end
      table.remove(node_stack)
      local node = node_stack[#node_stack]
      local sr, sc, er, ec = node:range()
      vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
      vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
      vim.cmd('normal! gv')
    end, { desc = 'Decrement treesitter selection' })
  end,
}
