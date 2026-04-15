return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "saghen/blink.cmp",
      {
        "mason-org/mason.nvim",
        opts = {
          registries = {
            "github:mason-org/mason-registry",
            "github:Crashdummyy/mason-registry",
          },
        },
      },
      { "mason-org/mason-lspconfig.nvim", config = function() end },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
    },
    opts = {
      diagnostics = {
        update_in_insert = true,
        severity_sort = true,
        float = { border = "rounded", source = true },
        underline = { severity = { min = vim.diagnostic.severity.HINT } },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = TeamoXtremo.icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN]  = TeamoXtremo.icons.diagnostics.Warn,
            [vim.diagnostic.severity.INFO]  = TeamoXtremo.icons.diagnostics.Info,
            [vim.diagnostic.severity.HINT]  = TeamoXtremo.icons.diagnostics.Hint,
          },
        },
        virtual_text = { source = "if_many", spacing = 2 },
      },
      -- Language files under lua/languages/ extend these two tables.
      servers = {},
      setup = {},
    },
    config = function(_, opts)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
      end

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then return end

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("i", "<C-s>", vim.lsp.buf.signature_help, "Signature Help")

          map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", "Goto Definition")
          map("n", "gr", "<cmd>Telescope lsp_references<cr>", "Goto References")
          map("n", "gI", "<cmd>Telescope lsp_implementations<cr>", "Goto Implementation")
          map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")

          map("n", "<leader>lt", "<cmd>Telescope lsp_type_definitions<cr>", "[T]ype Definition")
          map("n", "<leader>lr", vim.lsp.buf.rename, "[R]ename")
          map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, "Code [A]ction")
          map("n", "<leader>lw", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "[W]orkspace Symbols")
          map("n", "<leader>le", vim.diagnostic.open_float, "Diagnostic [E]rror Float")
          map("n", "<leader>lc", vim.lsp.codelens.run, "[C]odelens Run")
          map("n", "<leader>li", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, "Toggle [I]nlay Hints")
          map("n", "<leader>lv", function()
            local on = vim.diagnostic.config().virtual_lines
            vim.diagnostic.config({
              virtual_text = on and true or false,
              virtual_lines = not on,
            })
          end, "Toggle [V]irtual Lines")

          if client:supports_method("textDocument/documentHighlight") then
            local hl = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = hl,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = hl,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
        callback = function(event)
          vim.lsp.buf.clear_references()
          pcall(vim.api.nvim_clear_autocmds, { group = "lsp-highlight", buffer = event.buf })
        end,
      })

      local ensure_installed = {}
      for name, server in pairs(opts.servers) do
        if server.enabled ~= false then
          server.capabilities = vim.tbl_deep_extend("force", capabilities, server.capabilities or {})

          -- A setup[name] hook either mutates `server` and returns nothing (we
          -- then run the default enable), or returns true to take over setup
          -- entirely (e.g. roslyn.nvim needs its own init path).
          local setup = opts.setup[name]
          local skip_default = setup and setup(name, server) == true

          if not skip_default then
            vim.lsp.config(name, server)
            vim.lsp.enable(name)
          end

          table.insert(ensure_installed, name)
        end
      end

      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
    end,
  },

  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
  },
}
