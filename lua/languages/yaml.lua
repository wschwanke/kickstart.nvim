return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        yamlls = {
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
        },
      },
    },
  },
}
