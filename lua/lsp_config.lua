return {
  'neovim/nvim-lspconfig',

  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/nvim-cmp',
    'L3MON4D3/LuaSnip',
    'saadparwaiz1/cmp_luasnip',
    'j-hui/fidget.nvim',
  },

  config = function()
    local cmp = require 'cmp'
    local cmp_lsp = require 'cmp_nvim_lsp'
    local capabilities = vim.tbl_deep_extend(
      'force',
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities()
    )
    local lspconfig = require 'lspconfig'

    require('fidget').setup {}
    require('mason').setup()
    require('mason-lspconfig').setup {
      ensure_installed = {
        'lua_ls',
        'gopls',
        'htmx',
        'jsonls',
        'tailwindcss',
        'eslint',
        'emmet_ls',
        'rust_analyzer',
        'tsserver',
        'csharp_ls',
      },
      handlers = {
        function(server_name) -- default handler (optional)
          require('lspconfig')[server_name].setup {
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
                  ["https://raw.githubusercontent.com/ansible-community/schemas/main/f/ansible.json"] = "/**/playbooks/**/*.yml"
                }
              }
            }
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

    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup {
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
      },
      mapping = cmp.mapping.preset.insert {
        ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
        ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
        ['<C-y>'] = cmp.mapping.confirm { select = true },
        ['<C-Space>'] = cmp.mapping.complete(),
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'luasnip' }, -- For luasnip users.
      }, {
        { name = 'path' },
      }),
    }

    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

    vim.diagnostic.config {
      -- update_in_insert = true,
      float = {
        focusable = false,
        style = 'minimal',
        border = 'rounded',
        source = 'always',
        header = '',
        prefix = '',
      },
    }
  end,
}
