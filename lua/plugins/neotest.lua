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
    'antoinemadec/FixCursorHold.nvim',
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
    end, { desc = 'Debug: Running Nearest Test' })

    vim.keymap.set('n', '<leader>tv', function()
      require('neotest').summary.toggle()
    end, { desc = 'Debug: Summary Toggle' })

    vim.keymap.set('n', '<leader>ts', function()
      require('neotest').run.run {
        suite = true,
        testify = true,
      }
    end, { desc = 'Debug: Running Test Suite' })

    -- vim.keymap.set('n', '<leader>td', function()
    --   require('neotest').run.run {
    --     suite = false,
    --     testify = true,
    --     strategy = 'dap',
    --   }
    -- end, { desc = 'Debug: Debug Nearest Test' })

    vim.keymap.set('n', '<leader>to', function()
      require('neotest').output.open()
    end, { desc = 'Debug: Open test output' })

    vim.keymap.set('n', '<leader>ta', function()
      require('neotest').run.run(vim.fn.getcwd())
    end, { desc = 'Debug: Open test output' })
  end,
}
