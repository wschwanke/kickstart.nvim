return {
	"neovim/nvim-lspconfig",

	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"L3MON4D3/LuaSnip",
		"j-hui/fidget.nvim",
		"saghen/blink.cmp",
		"creativenull/efmls-configs-nvim",
	},

	config = function()
		local lspconfig = require("lspconfig")
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		require("fidget").setup({})
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"gopls",
				"htmx",
				"jsonls",
				"tailwindcss",
				"emmet_ls",
				"rust_analyzer",
				"ts_ls",
				"csharp_ls",
				"efm",
			},
			handlers = {
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,

				["efm"] = function()
					local languages = require("efmls-configs.defaults").languages()

					lspconfig.efm.setup({
						filetypes = { "lua", "typescript", "javascript", "typescriptreact", "javascriptreact" },
						init_options = {
							documentFormatting = true,
							documentRangeFormatting = true,
						},
						settings = {
							rootMarkers = { ".git/" },
							languages = languages,
						},
						capabilities = capabilities,
					})
				end,

				["yamlls"] = function()
					lspconfig.yamlls.setup({
						capabilities = capabilities,
						on_attach = function(client)
							client.server_capabilities.documentFormattingProvider = true
						end,
						settings = {
							yaml = {
								schemas = {
									["https://raw.githubusercontent.com/ansible-community/schemas/main/f/ansible.json"] =
									"/**/playbooks/**/*.yml",
								},
							},
						},
					})
				end,

				["tailwindcss"] = function()
					lspconfig.tailwindcss.setup({
						capabilities = capabilities,
						settings = {
							tailwindCSS = {
								experimental = {
									classRegex = {
										"class:\\s*?[\"'`]([^\"'`]*).*?,",
										"clsx\\(([^)]*)\\)",
										"cva\\(([^)]*)\\)",
										"cn\\(([^)]*)\\)",
										"(class|className)=[\"'`]([^\"'`]*).*?[\"'`]",
									},
								},
							},
						},
					})
				end,

				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim", "it", "describe", "before_each", "after_each" },
								},
							},
						},
					})
				end,
			},
		})

		vim.diagnostic.config({
			-- update_in_insert = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})

		vim.keymap.set("n", "<leader>f", function()
			vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
		end)
	end,
}
