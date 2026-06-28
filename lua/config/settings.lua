local M = {}

-- Must match a plugin spec in lua/config/themes.lua.
M.theme = "everforest"

M.treesitter = {
  "astro",
  "bash",
  "c",
  "c_sharp",
  "css",
  "diff",
  "dockerfile",
  "ecma",
  "eex",
  "elixir",
  "git_rebase",
  "gitcommit",
  "gitignore",
  "glsl",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "heex",
  "hlsl",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "jsx",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "odin",
  "printf",
  "prisma",
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
    Warn = "󰀪 ",
    Info = "󰋽 ",
    Hint = "󰌶 ",
  },
  git = {
    added = " ",
    modified = " ",
    removed = " ",
  },
}

return M
