# Agent Guidelines for Neovim Config

## Commands
- **Format**: `stylua .` (2 spaces, 120 column width)
- **Lint**: `luacheck .` (vim is defined as global)
- **No tests** - this is a configuration repository

## Code Style
- **Indentation**: 2 spaces, expandtab (configured in options.lua)
- **Imports**: `require 'module'` (no parens for single strings), `require('module')` when needed
- **Quotes**: Single quotes preferred but mixed usage acceptable
- **Naming**: snake_case for local variables/functions
- **Comments**: Use `--` sparingly; explain why not what (NO comments unless necessary)
- **Plugin format**: Return lazy.nvim spec table with `config`, `dependencies`, `opts` fields
- **Keymaps**: Always include descriptive `desc` field (e.g., `desc = '[S]earch [F]iles'`)
- **Functions**: `local function name()` for locals, standard Lua function syntax
- **Type annotations**: Use LuaCATS format (`---@param`, `---@return`) for LSP functions
- **Tables**: Proper spacing, trailing commas acceptable
- **Error handling**: Use `pcall()` for operations that may fail (see telescope.lua)

## Structure
- Config entry: `init.lua` loads options, lazy, lsp_config, keymaps, autocmds
- Plugins: Individual files in `lua/plugins/` return lazy.nvim specs
- LSP: Configured via `lua/lsp_config.lua` with mason-lspconfig handlers
