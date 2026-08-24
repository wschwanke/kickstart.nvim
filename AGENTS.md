# Neovim config layout

Plugin manager is lazy.nvim, bootstrapped in `init.lua`, which imports four spec roots: `config/themes`, `plugins`, `languages`, `formatting`. Every `.lua` file in those directories is auto-loaded as a plugin spec — no manual registration anywhere.

## Directories

- `lua/config/` — core: `options.lua`, `keymaps.lua`, `autocmds.lua`, `themes.lua`; `settings.lua` holds central lists (theme name, tree-sitter parsers, icons), exposed globally as `_G.TeamoXtremo` via `teamoxtremo.lua`.
- `lua/plugins/` — one spec per plugin. Key infra: `lsp.lua`, `treesitter.lua`, `format.lua` (conform.nvim), `linting.lua` (nvim-lint).
- `lua/languages/` — one file per language; extends the infra specs below.
- `lua/formatting/` — cross-language formatters (prettier, biome) that gate on project config files.
- `after/ftplugin/` — per-filetype buffer options.

## Adding a language

Create `lua/languages/<lang>.lua` returning specs that extend (lazy deep-merges `opts`):

- **LSP**: `{ "neovim/nvim-lspconfig", opts = { servers = { <name> = {...} } } }`. `lua/plugins/lsp.lua` enables each via `vim.lsp.config`/`vim.lsp.enable` and auto-installs through mason-tool-installer. Escape hatches: `mason = false` (binary not from Mason, e.g. qmlls), `enabled = false`, or a `setup.<name>` hook returning `true` to take over setup (see `csharp.lua`).
- **Mason tools** (non-LSP binaries): `tools = { "mbake", ... }` alongside `servers` — merged into the same auto-install list.
- **Tree-sitter**: add the parser name to `M.treesitter` in `lua/config/settings.lua` (alphabetical). `lua/plugins/treesitter.lua` (nvim-treesitter `main` branch) auto-installs and wires highlight/indent/folds via a FileType autocmd.
- **Formatter**: `{ "stevearc/conform.nvim", opts = { formatters_by_ft = { <ft> = { "<formatter>" } } } }`. Format is manual: `<leader>f` (no format-on-save).
- **Linter**: `{ "mfussenegger/nvim-lint", opts = { linters_by_ft = { <ft> = { "<linter>" } } } }`. Runs on save/read/InsertLeave.

`lua/languages/make.lua` shows all four blocks together; `bash.lua` is the minimal LSP-only shape.

## Gotchas

- `mason.nvim` v2 ignores `opts.ensure_installed` — the only working auto-installer is the mason-tool-installer call in `lua/plugins/lsp.lua`, fed by `servers` + `tools`.
- mason-lspconfig is installed but deliberately neutered (`config = function() end`); it only supplies name mappings.
- Extra Mason registry: `github:Crashdummyy/mason-registry` (for roslyn).
