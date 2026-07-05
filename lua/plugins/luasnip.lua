return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    build = (function()
      if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
        return -- jsregexp is optional; skip where make isn't available
      end
      return "make install_jsregexp"
    end)(),
    config = function()
      local luasnip = require("luasnip")

      require("luasnip.loaders.from_snipmate").lazy_load({
        paths = { vim.fs.joinpath(vim.fn.stdpath("config"), "snippets") },
      })
    end,
  },
  {
    "danymat/neogen",
    optional = true,
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      snippet_engine = "luasnip", -- This is all you need
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      snippets = {
        preset = "luasnip",
      },
    },
  },
}
