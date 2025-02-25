return {
	'smithbm2316/centerpad.nvim',
	config = function()
		vim.api.nvim_set_keymap('n', '<leader>z', "<cmd>lua require'centerpad'.toggle{ leftpad = 63, rightpad = 63 }<cr>",
			{ silent = true, noremap = true })
		vim.api.nvim_set_keymap('n', '<leader>Z', "<cmd>lua require'centerpad'.toggle{ leftpad = 30, rightpad = 30 }<cr>",
			{ silent = true, noremap = true })
	end,
}
