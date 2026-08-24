-- Quickshell aliases the shell config root as the `qs` module namespace at
-- runtime, but qmlls only sees plain import paths. A shim directory whose
-- `qs` entry symlinks to Omarchy's shell root makes `import qs.Commons`
-- resolve: <shim>/qs/Commons/qmldir declares `module qs.Commons`.
local function qs_shim()
  local shim = vim.fn.expand("~/.local/state/qmlls-shim")
  local target = (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/shell"
  if vim.fn.isdirectory(target) == 0 then
    return nil
  end
  vim.fn.mkdir(shim, "p")
  local link = shim .. "/qs"
  if not vim.uv.fs_lstat(link) then
    vim.uv.fs_symlink(target, link)
  end
  return shim
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          -- qmlls ships with Qt (qt6-languageserver on Arch), not Mason.
          mason = false,
          cmd = (function()
            local bin = "/usr/lib/qt6/bin/qmlls"
            if vim.fn.executable("qmlls") == 1 then
              bin = "qmlls"
            end
            -- -E resolves imports from QML_IMPORT_PATH in the environment.
            local cmd = { bin, "-E", "-I", "/usr/lib/qt6/qml" }
            local shim = qs_shim()
            if shim then
              vim.list_extend(cmd, { "-I", shim })
            end
            return cmd
          end)(),
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        qml = { "prettier" },
      },
    },
  },
}
