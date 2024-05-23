local ls = require('luasnip')
-- some shorthands...
local s = ls.snippet
-- local sn = ls.snippet_node
local t = ls.text_node
-- local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node
-- local r = ls.restore_node
-- local l = require("luasnip.extras").lambda
-- local rep = require("luasnip.extras").rep
-- local p = require("luasnip.extras").partial
-- local m = require("luasnip.extras").match
-- local n = require("luasnip.extras").nonempty
-- local dl = require("luasnip.extras").dynamic_lambda
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local types = require("luasnip.util.types")
-- local conds = require("luasnip.extras.conditions")
-- local conds_expand = require("luasnip.extras.conditions.expand")

local function external_dependencies_jsts()
  return s('edc', {
    t({ '/**', ' * External dependencies', ' */', '' }),
  })
end

local function internal_dependencies_jsts()
  return s('idc', {
    t({ '/**', ' * Internal dependencies', ' */', '' }),
  })
end

ls.add_snippets("javascript", {
  external_dependencies_jsts(),
  internal_dependencies_jsts(),
})
ls.add_snippets("javascriptreact", {
  external_dependencies_jsts(),
  internal_dependencies_jsts(),
})
ls.add_snippets("typescript", {
  external_dependencies_jsts(),
  internal_dependencies_jsts(),
})
ls.add_snippets("typescriptreact", {
  external_dependencies_jsts(),
  internal_dependencies_jsts(),
})
