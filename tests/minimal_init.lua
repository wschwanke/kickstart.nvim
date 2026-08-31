-- Minimal runtime for the docgen test suite (plenary.busted). Keeps the user's
-- plugins and config out of the run -- only plenary, this repo, and treesitter
-- parsers are needed.
--
--   nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/docgen/"
vim.opt.runtimepath:prepend(vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "plenary.nvim"))
vim.opt.runtimepath:prepend(vim.fn.stdpath("config"))
