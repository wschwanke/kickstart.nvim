-- Match Odin's official comment structure (see examples/demo/demo.odin):
-- block-comment bodies sit flush with the `/*` line, with no "*" leader and
-- no extra indent.
--
-- Neovim's built-in Odin ftplugin (runtime/ftplugin/odin.vim) sets:
--   comments=s1:/*,mb:*,ex:*/,://
-- Any three-piece definition makes Enter/o auto-insert a (non-empty) middle
-- leader plus the s{N} offset as indentation inside a /* */ block, and Vim
-- rejects an empty leader. Dropping the three-piece keeps `//` auto-continuing
-- (formatoptions r/o) while block-comment bodies just follow autoindent, i.e.
-- the enclosing proc's tabs. Trade-off: `gqip` inside a block no longer knows
-- `/*` and `*/` are delimiters, so format body lines with a visual selection.
vim.opt_local.comments = "://"

-- Odin uses real tabs (odinfmt.json: tabs=true, tabs_width=4). The global
-- expandtab/tabstop=2 makes odinfmt's tabs render 2 wide and typed indents
-- come out as spaces — override per-buffer to match the formatter.
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
