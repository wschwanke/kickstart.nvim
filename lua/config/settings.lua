local M = {}

-- Must match a plugin spec in lua/config/themes.lua.
M.theme = "gruvbox-material"

M.treesitter = {
  "bash",
  "c",
  "c_sharp",
  "css",
  "diff",
  "dockerfile",
  "eex",
  "elixir",
  "git_rebase",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "heex",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "prisma",
  "printf",
  "python",
  "query",
  "razor",
  "regex",
  "scss",
  "svelte",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
  "zig",
}

M.icons = {
  diagnostics = {
    Error = "󰅚 ",
    Warn  = "󰀪 ",
    Info  = "󰋽 ",
    Hint  = "󰌶 ",
  },
  git = {
    added    = " ",
    modified = " ",
    removed  = " ",
  },
}

return M
