return {
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		build = "make install_jsregexp",
		config = function()
			local luasnip = require('luasnip')

			require('luasnip.loaders.from_snipmate').lazy_load({
				paths = { vim.fn.stdpath('config') .. '/snippets' }
			})

			-- Global snippet navigation keymaps
			vim.keymap.set({ 'i', 's' }, '<C-l>', function()
				if luasnip.expand_or_locally_jumpable() then
					luasnip.expand_or_jump()
				end
			end, { silent = true, desc = 'Jump forward in snippet' })

			vim.keymap.set({ 'i', 's' }, '<C-h>', function()
				if luasnip.locally_jumpable(-1) then
					luasnip.jump(-1)
				end
			end, { silent = true, desc = 'Jump backward in snippet' })
		end,
	},
	{
		'danymat/neogen',
		dependencies = { 'L3MON4D3/LuaSnip' },
		opts = {
			snippet_engine = 'luasnip', -- This is all you need
		},
	},
	{
		"saghen/blink.cmp",
		optional = true,
		opts = {
			snippets = {
				preset = "luasnip",
			},
		},
	},

}
