return {
	'saghen/blink.cmp',
	dependencies = { 'rafamadriz/friendly-snippets' },
	-- version = '0.9.3',
	version = '*',

	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = { preset = 'default' },

		completion = {
			menu = {
				draw = {
					columns = {
						{ 'kind_icon' },
						{ 'label',    'label_description', 'source_file', gap = 1 },
					},
					components = {
						source_file = {
							text = function(ctx)
								if ctx.item.detail then
									return ctx.item.detail
								elseif ctx.item.documentation then
									return ctx.item.documentation
								end
							end,
							highlight = 'BlinkCmpSource', -- Define a highlight group for styling
						},
					},
				},
			},
		},

		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = 'mono',
		},

		sources = {
			default = { 'lsp', 'path', 'snippets', 'buffer' },
		},
	},
	opts_extend = { 'sources.default' },
}
