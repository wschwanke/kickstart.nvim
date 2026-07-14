-- Match Odin's official comment structure (see examples/demo/demo.odin):
-- block-comment bodies are indented with no "*" leader.
--
-- Neovim's built-in Odin ftplugin (runtime/ftplugin/odin.vim) sets:
--   comments=s1:/*,mb:*,ex:*/,://
-- The mb:* middle leader is what auto-inserts a "*" on each new line of a
-- /* */ block. Swap that middle leader for a single space ("mb: ") so the
-- body still auto-indents on Enter/o (via formatoptions r/o) but without the
-- "*". Treesitter's indentexpr won't indent inside a comment node, so this
-- leader is what restores the indentation.
-- vim.opt_local.comments = "s1:/*,mb: ,ex:*/,://"

-- Odin uses real tabs (odinfmt.json: tabs=true, tabs_width=4). The global
-- expandtab/tabstop=2 makes odinfmt's tabs render 2 wide and typed indents
-- come out as spaces — override per-buffer to match the formatter.
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
