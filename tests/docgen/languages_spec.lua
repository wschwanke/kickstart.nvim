-- Tests for the per-language specs: anchors, insert rows, existing-doc detection,
-- and response extraction. Each test parses real code with the real treesitter parser.
local languages = require("utils.docgen.languages")

local function buf_from(code, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = ft
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(code, "\n", { plain = true }))
  return buf
end

local function parse(buf, lang)
  return vim.treesitter.get_parser(buf, lang):parse()[1]:root()
end

-- Depth-first search for the first node of the given type.
local function find(node, t)
  if node:type() == t then
    return node
  end
  for child in node:iter_children() do
    if child:named() then
      local hit = find(child, t)
      if hit then
        return hit
      end
    end
  end
end

-- All nodes in the tree for which pred is true.
local function collect(node, pred, out)
  out = out or {}
  if pred(node) then
    out[#out + 1] = node
  end
  for child in node:iter_children() do
    if child:named() then
      collect(child, pred, out)
    end
  end
  return out
end

describe("docgen lua spec", function()
  local spec = languages.specs.lua

  it("anchors `function M.bar()` declarations and reports the dotted name", function()
    local buf = buf_from("function M.bar() return 1 end\n", "lua")
    local node = find(parse(buf, "lua"), "function_declaration")
    assert.truthy(spec.is_function(node, buf))
    local anchor = spec.anchor(node, buf)
    assert.equals("function_declaration", anchor:type())
    assert.equals("M.bar", spec.fn_name(anchor, buf))
    assert.equals(0, spec.insert_row(anchor, buf))
  end)

  it("anchors `M.foo = function()` via the assignment statement", function()
    local buf = buf_from("M.foo = function() return 2 end\n", "lua")
    local node = find(parse(buf, "lua"), "function_definition")
    assert.truthy(spec.is_function(node, buf))
    local anchor = spec.anchor(node, buf)
    assert.equals("assignment_statement", anchor:type())
    assert.equals("M.foo", spec.fn_name(anchor, buf))
  end)

  it("handles `local x = function()` with a variable_declaration anchor", function()
    local buf = buf_from("local x = function() return 1 end\n", "lua")
    local node = find(parse(buf, "lua"), "function_definition")
    assert.truthy(spec.is_function(node, buf))
    local anchor = spec.anchor(node, buf)
    assert.equals("variable_declaration", anchor:type())
    assert.equals("x", spec.fn_name(anchor, buf))
    assert.equals(0, spec.insert_row(anchor, buf))
  end)

  it("picks up contiguous `---` comments as existing docs", function()
    local buf = buf_from("--- Old docs.\n---@param buf integer\nlocal function foo(buf) end\n", "lua")
    local node = find(parse(buf, "lua"), "function_declaration")
    assert.same({ start_row = 0, end_row = 2 }, spec.existing_doc(node, buf))
  end)

  it("extracts `---` lines and drops preceding prose", function()
    local out = spec.extract({ "Sure, here you go:", "--- Does the thing.", "---@param a integer", "" })
    assert.same({ "--- Does the thing.", "---@param a integer" }, out)
  end)
end)

describe("docgen javascript spec", function()
  local spec = languages.specs.javascript

  it("anchors exported arrow functions and resolves their name", function()
    local buf = buf_from("export const foo = () => {\n  return 1\n};\n", "javascript")
    local node = find(parse(buf, "javascript"), "variable_declarator")
    assert.truthy(spec.is_function(node, buf))
    local anchor = spec.anchor(node, buf)
    assert.equals("export_statement", anchor:type())
    assert.equals(0, spec.insert_row(anchor, buf))
    assert.equals("foo", spec.fn_name(anchor, buf))
  end)

  it("inserts above method decorators", function()
    local buf = buf_from(table.concat({
      "class Foo {",
      "  @Observe('x')",
      "  bar() {}",
      "}",
    }, "\n"), "javascript")
    local node = find(parse(buf, "javascript"), "method_definition")
    assert.truthy(spec.is_function(node, buf))
    assert.equals(1, spec.insert_row(node, buf)) -- row of the decorator
  end)

  it("treats /** comments as existing docs but not // comments", function()
    local block = buf_from("/** Old. */\nfunction foo() {}\n", "javascript")
    local fn = find(parse(block, "javascript"), "function_declaration")
    assert.same({ start_row = 0, end_row = 1 }, spec.existing_doc(fn, block))

    local line = buf_from("// notes\nfunction foo() {}\n", "javascript")
    local fn2 = find(parse(line, "javascript"), "function_declaration")
    assert.is_nil(spec.existing_doc(fn2, line))
  end)

  it("extracts /** blocks and drops surrounding prose", function()
    local out = spec.extract({ "Here you go:", "/**", " * Does things.", " */", "trailing prose" })
    assert.same({ "/**", " * Does things.", " */" }, out)
  end)
end)

describe("docgen typescript spec", function()
  it("shares the javascript grammar shapes", function()
    local spec = languages.specs.typescript
    assert.equals("typescript", spec.name)
    assert.equals(languages.specs.javascript.is_function, spec.is_function)
    assert.equals(languages.specs.javascript.existing_doc, spec.existing_doc)
  end)
end)

describe("docgen elixir spec", function()
  local spec = languages.specs.elixir
  local code = table.concat({
    "defmodule Demo do",
    "  @doc \"\"\"",
    "  Old docs",
    "  \"\"\"",
    "  def foo(a) do",
    "    a + 1",
    "  end",
    "  def foo(b) when is_integer(b) do",
    "    b * 2",
    "  end",
    "end",
  }, "\n")

  it("anchors multi-clause defs at the first clause", function()
    local buf = buf_from(code, "elixir")
    local defs = collect(parse(buf, "elixir"), function(n)
      return spec.is_function(n, buf)
    end)
    assert.equals(2, #defs)
    local anchor = spec.anchor(defs[2], buf)
    assert.equals(defs[1]:id(), anchor:id())
    assert.equals("foo", spec.fn_name(anchor, buf))
  end)

  it("treats the @doc heredoc as existing doc", function()
    local buf = buf_from(code, "elixir")
    local defs = collect(parse(buf, "elixir"), function(n)
      return spec.is_function(n, buf)
    end)
    assert.same({ start_row = 1, end_row = 4 }, spec.existing_doc(defs[1], buf))
  end)

  it("extracts the @doc heredoc, optionally appending an @spec", function()
    local lines = { '@doc """', "  Old docs", '  """', "@spec foo(integer) :: integer" }
    local off = spec.extract(lines, { elixir = { spec = false } }, { source = "" })
    assert.same({ '@doc """', "  Old docs", '  """' }, off)

    local on = spec.extract(lines, { elixir = { spec = true } }, { source = "" })
    assert.same(lines, on)

    -- @spec already present in the source: not appended a second time
    local have = spec.extract(lines, { elixir = { spec = true } }, { source = "@spec foo(integer) :: integer" })
    assert.same(off, have)
  end)
end)

describe("docgen odin spec", function()
  local spec = languages.specs.odin
  local code = table.concat({
    "package main",
    "",
    "@(private)",
    "add :: proc(a, b: int) -> int {",
    "\treturn a + b",
    "}",
    "MAX :: 10",
  }, "\n")

  it("anchors procs above their attributes and reports the name", function()
    local buf = buf_from(code, "odin")
    local proc = find(parse(buf, "odin"), "procedure_declaration")
    assert.truthy(spec.is_function(proc, buf))
    assert.equals(proc:id(), spec.anchor(proc, buf):id())
    assert.equals(2, spec.insert_row(proc, buf)) -- the @(private) row
    assert.equals("add", spec.fn_name(proc, buf))
  end)

  it("counts file-scope constants but not local variables", function()
    local buf = buf_from(code, "odin")
    local konst = find(parse(buf, "odin"), "const_declaration")
    assert.truthy(spec.is_function(konst, buf))

    local buf2 = buf_from("f :: proc() {\n\tx := 1\n\tg : int = 2\n}\n", "odin")
    local root = parse(buf2, "odin")
    -- `x := 1` is an assignment_statement, `g : int = 2` a var_declaration; neither
    -- counts as a documentable declaration when it sits inside a proc body.
    local locals = collect(root, function(n)
      return n:type() == "assignment_statement" or n:type() == "var_declaration"
    end)
    assert.equals(2, #locals)
    for _, n in ipairs(locals) do
      assert.falsy(spec.is_function(n, buf2))
    end
  end)

  it("extracts block comments and // runs", function()
    assert.same({ "/*", " text", " */" }, spec.extract({ "prose", "/*", " text", " */", "prose" }))
    assert.same({ "// a", "// b" }, spec.extract({ "// a", "// b" }))
  end)

  it("collapses short constants to // lines via finalize", function()
    local one = spec.finalize({ "\t/* Releases textures. */" }, { kind = "const_declaration" })
    assert.same({ "\t// Releases textures." }, one)

    local three = spec.finalize({ "\t/*", "\tReleases textures.", "\t*/" }, { kind = "const_declaration" })
    assert.same({ "\t// Releases textures." }, three)

    local proc = spec.finalize({ "\t/*", "\tReleases textures.", "\t*/" }, { kind = "procedure_declaration" })
    assert.equals(3, #proc)
  end)
end)
