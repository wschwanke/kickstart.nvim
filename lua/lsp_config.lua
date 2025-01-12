return {
  'neovim/nvim-lspconfig',

  dependencies = {
    'creativenull/efmls-configs-nvim',
    'hrsh7th/cmp-nvim-lsp',
    'j-hui/fidget.nvim',
    'neovim/nvim-lspconfig',
    'williamboman/mason-lspconfig.nvim',
    'williamboman/mason.nvim',
  },

  config = function()
    local lspconfig = require 'lspconfig'
    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    require('fidget').setup {}
    require('mason').setup()
    require('mason-lspconfig').setup {
      ensure_installed = {
        'csharp_ls',
        'efm',
        'gopls',
        'jsonls',
        'lua_ls',
        'rust_analyzer',
        'tailwindcss',
        'ts_ls',
      },
      handlers = {
        function(server_name) -- default handler (optional)
          require('lspconfig')[server_name].setup {
            capabilities = capabilities,
          }
        end,

        ['efm'] = function()
          local languages = require('efmls-configs.defaults').languages()

          lspconfig.efm.setup {
            filetypes = { 'lua', 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
            init_options = {
              documentFormatting = true,
              documentRangeFormatting = true,
            },
            settings = {
              rootMarkers = { '.git/' },
              languages = languages,
            },
            capabilities = capabilities,
          }
        end,

        ['yamlls'] = function()
          lspconfig.yamlls.setup {
            capabilities = capabilities,
            on_attach = function(client)
              client.server_capabilities.documentFormattingProvider = true
            end,
            settings = {
              yaml = {
                schemas = {
                  ['https://raw.githubusercontent.com/ansible-community/schemas/main/f/ansible.json'] = '/**/playbooks/**/*.yml',
                },
              },
            },
          }
        end,

        ['tailwindcss'] = function()
          lspconfig.tailwindcss.setup {
            capabilities = capabilities,
            settings = {
              tailwindCSS = {
                experimental = {
                  classRegex = {
                    'class:\\s*?["\'`]([^"\'`]*).*?,',
                    'clsx\\(([^)]*)\\)',
                    'cva\\(([^)]*)\\)',
                    'cn\\(([^)]*)\\)',
                    '(class|className)=["\'`]([^"\'`]*).*?["\'`]',
                  },
                },
              },
            },
          }
        end,

        ['lua_ls'] = function()
          lspconfig.lua_ls.setup {
            capabilities = capabilities,
            settings = {
              Lua = {
                diagnostics = {
                  globals = { 'vim', 'it', 'describe', 'before_each', 'after_each' },
                },
              },
            },
          }
        end,
      },
    }

    -- vim.diagnostic.config {
    --   -- update_in_insert = true,
    --   float = {
    --     focusable = false,
    --     style = 'minimal',
    --     border = 'rounded',
    --     source = 'always',
    --     header = '',
    --     prefix = '',
    --   },
    -- }

  end,
}
