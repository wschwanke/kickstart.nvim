return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'saghen/blink.cmp',
      { 'mason-org/mason.nvim', opts = {} },
      { 'mason-org/mason-lspconfig.nvim', config = function() end },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    opts_extend = { 'servers.*.keys' },
    opts = function()
      return {
        diagnostics = {
          update_in_insert = true,
          severity_sort = true,
          float = { border = 'rounded', source = true },
          underline = { severity = { min = vim.diagnostic.severity.HINT } },
          signs = vim.g.have_nerd_font and {
            text = {
              [vim.diagnostic.severity.ERROR] = '󰅚 ',
              [vim.diagnostic.severity.WARN] = '󰀪 ',
              [vim.diagnostic.severity.INFO] = '󰋽 ',
              [vim.diagnostic.severity.HINT] = '󰌶 ',
            },
          } or {},
          virtual_text = {
            source = 'if_many',
            spacing = 2,
            format = function(diagnostic)
              local diagnostic_message = {
                [vim.diagnostic.severity.ERROR] = diagnostic.message,
                [vim.diagnostic.severity.WARN] = diagnostic.message,
                [vim.diagnostic.severity.INFO] = diagnostic.message,
                [vim.diagnostic.severity.HINT] = diagnostic.message,
              }
              return diagnostic_message[diagnostic.severity]
            end,
          },
        },
        inlay_hints = {
          enabled = false,
          exclude = {},
        },
        codelens = {
          enabled = true,
        },
        folds = {
          enabled = false,
        },
        servers = {
          ['*'] = {
            capabilities = {},
            keys = {
              { 'K', vim.lsp.buf.hover, desc = 'Hover' },
              { '<C-s>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help', has = 'signatureHelp' },
              { '<leader>vd', '<cmd>Telescope diagnostics<cr>', desc = 'LSP: Open [D]iagnostics' },
              { '<leader>vrr', '<cmd>Telescope lsp_references<cr>', desc = 'LSP: [R]eferences' },
              { 'gd', '<cmd>Telescope lsp_definitions<cr>', desc = 'LSP: [G]oto [D]efinition', has = 'definition' },
              { 'gr', '<cmd>Telescope lsp_references<cr>', desc = 'LSP: [G]oto [R]eferences' },
              { 'gI', '<cmd>Telescope lsp_implementations<cr>', desc = 'LSP: [G]oto [I]mplementation' },
              { '<leader>vD', '<cmd>Telescope lsp_type_definitions<cr>', desc = 'LSP: Type [D]efinition' },
              { '<leader>vds', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'LSP: [D]ocument [S]ymbols' },
              { '<leader>vws', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'LSP: [W]orkspace [S]ymbols' },
              { '<leader>vrn', vim.lsp.buf.rename, desc = 'LSP: [R]e[n]ame', has = 'rename' },
              { '<leader>vca', vim.lsp.buf.code_action, desc = 'LSP: [C]ode [A]ction', mode = { 'n', 'x' }, has = 'codeAction' },
              { 'gD', vim.lsp.buf.declaration, desc = 'LSP: [G]oto [D]eclaration' },
            },
          },
        },
        setup = {},
      }
    end,
    config = vim.schedule_wrap(function(_, opts)
      local have_blink, blink = pcall(require, 'blink.cmp')
      if have_blink then
        opts.servers['*'].capabilities = vim.tbl_deep_extend('force', blink.get_lsp_capabilities(), opts.servers['*'].capabilities or {})
      end

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      local function check_capability(client, capability)
        if not capability then
          return true
        end

        if type(capability) == 'string' then
          local method = capability:find('/') and capability or ('textDocument/' .. capability)
          local clients = vim.lsp.get_clients {
            bufnr = vim.api.nvim_get_current_buf(),
            name = client.name,
            method = method,
          }
          return #clients > 0
        end

        if type(capability) == 'table' then
          for _, cap in ipairs(capability) do
            if check_capability(client, cap) then
              return true
            end
          end
          return false
        end

        return true
      end

      local function setup_keymaps(client, buffer)
        local Keys = require 'lazy.core.handler.keys'
        local keymaps = {}

        for _, value in ipairs(opts.servers['*'].keys or {}) do
          keymaps[#keymaps + 1] = value
        end

        local server_name = client.name
        if opts.servers[server_name] and opts.servers[server_name].keys then
          for _, value in ipairs(opts.servers[server_name].keys) do
            keymaps[#keymaps + 1] = value
          end
        end

        for _, keys in pairs(Keys.resolve(keymaps)) do
          if check_capability(client, keys.has) then
            local keymap_opts = Keys.opts(keys)
            keymap_opts.has = nil
            keymap_opts.buffer = buffer
            vim.keymap.set(keys.mode or 'n', keys.lhs, keys.rhs, keymap_opts)
          end
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client then
            setup_keymaps(client, event.buf)

            if client.server_capabilities.documentHighlightProvider then
              local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
              vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
              })

              vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
              })

              vim.api.nvim_create_autocmd('LspDetach', {
                group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
                callback = function(event2)
                  vim.lsp.buf.clear_references()
                  vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
                end,
              })
            end
          end
        end,
      })

      if opts.inlay_hints.enabled then
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('lsp-inlay-hints', { clear = true }),
          callback = function(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if
              client
              and client.server_capabilities.inlayHintProvider
              and vim.api.nvim_buf_is_valid(event.buf)
              and vim.bo[event.buf].buftype == ''
              and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[event.buf].filetype)
            then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
          end,
        })
      end

      if opts.codelens.enabled and vim.lsp.codelens then
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('lsp-codelens', { clear = true }),
          callback = function(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if client and client.server_capabilities.codeLensProvider then
              vim.lsp.codelens.refresh()
              vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
                buffer = event.buf,
                callback = vim.lsp.codelens.refresh,
              })
            end
          end,
        })
      end

      if opts.servers['*'] then
        vim.lsp.config('*', opts.servers['*'])
      end

      local have_mason, mason_lspconfig = pcall(require, 'mason-lspconfig')
      local all_servers = have_mason and vim.tbl_keys(require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package) or {}
      local mason_exclude = {}

      local function configure(server)
        if server == '*' then
          return false
        end

        local server_opts = opts.servers[server]
        server_opts = server_opts == true and {} or (not server_opts) and { enabled = false } or server_opts

        if server_opts.enabled == false then
          mason_exclude[#mason_exclude + 1] = server
          return
        end

        local use_mason = server_opts.mason ~= false and vim.tbl_contains(all_servers, server)
        local setup = opts.setup[server] or opts.setup['*']

        if setup and setup(server, server_opts) then
          mason_exclude[#mason_exclude + 1] = server
        else
          vim.lsp.config(server, server_opts)
          if not use_mason then
            vim.lsp.enable(server)
          end
        end

        return use_mason
      end

      local ensure_installed = vim.tbl_filter(configure, vim.tbl_keys(opts.servers))
      vim.list_extend(ensure_installed, { 'biome' })

      local filtered_ensure = vim.tbl_filter(function(server)
        return server ~= '*'
      end, ensure_installed)

      require('mason-tool-installer').setup { ensure_installed = filtered_ensure }

      if have_mason then
        mason_lspconfig.setup {
          ensure_installed = {},
          automatic_installation = false,
          handlers = {
            function(server_name)
              vim.lsp.enable(server_name)
            end,
          },
        }
      end
    end),
  },

  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts_extend = { 'ensure_installed' },
    opts = {
      ensure_installed = {},
    },
    config = function(_, opts)
      require('mason').setup(opts)
      local mr = require 'mason-registry'
      mr:on('package:install:success', function()
        vim.defer_fn(function()
          require('lazy.core.handler.event').trigger {
            event = 'FileType',
            buf = vim.api.nvim_get_current_buf(),
          }
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
}
