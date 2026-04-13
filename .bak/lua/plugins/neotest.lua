return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/neotest-plenary',
    'fredrikaverpil/neotest-golang',
    'lawrence-laz/neotest-zig',
    'jfpedroza/neotest-elixir',
    'nvim-neotest/neotest-jest',
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-plenary',
        require 'neotest-elixir',
        require 'neotest-zig',
        require 'neotest-golang',
        require 'neotest-jest' {
          jestCommand = 'npm test --',
          jestArguments = function(defaultArguments, context)
            return defaultArguments
          end,
          jestConfigFile = 'custom.jest.config.ts',
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
          isTestFile = require('neotest-jest.jest-util').defaultIsTestFile,
        },
      },
    }

    vim.keymap.set('n', '<leader>tr', function()
      require('neotest').run.run {
        suite = false,
        testify = true,
      }
    end, { desc = 'Test: [R]un Nearest' })

    vim.keymap.set('n', '<leader>tv', function()
      require('neotest').summary.toggle()
    end, { desc = 'Test: Toggle Summary [V]iew' })

    vim.keymap.set('n', '<leader>ts', function()
      require('neotest').run.run {
        suite = true,
        testify = true,
      }
    end, { desc = 'Test: Run [S]uite' })

    vim.keymap.set('n', '<leader>to', function()
      require('neotest').output.open()
    end, { desc = 'Test: [O]pen Output' })

    vim.keymap.set('n', '<leader>ta', function()
      require('neotest').run.run(vim.fn.getcwd())
    end, { desc = 'Test: Run [A]ll' })
  end,
}
