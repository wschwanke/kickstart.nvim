-- Tests for the pure prompt/post-processing functions in utils.docgen.format.
local format = require("utils.docgen.format")

describe("docgen.format.strip_fences", function()
  it("trims trailing whitespace and drops blank edge lines", function()
    assert.same({ "a", "  b" }, format.strip_fences("a   \n  b   \n\n\n"))
  end)

  it("keeps only the first fenced block", function()
    assert.same({ "hi" }, format.strip_fences("prose\n```lua\nhi\n```\nprose after"))
  end)

  it("keeps everything after an unterminated fence", function()
    assert.same({ "hi" }, format.strip_fences("```\nhi"))
  end)
end)

describe("docgen.format.dedent", function()
  it("removes common indent from non-blank lines", function()
    assert.same({ "a", "b", "" }, format.dedent({ "  a", "  b", "" }))
  end)

  it("leaves lines without a common indent alone", function()
    local lines = { "a", "  b" }
    assert.same(lines, format.dedent(lines))
  end)
end)

describe("docgen.format.wrap", function()
  it("joins model line breaks and re-wraps to width (Odin block style)", function()
    local out = format.wrap({
      "/*",
      "Releases the GPU textures",
      "held by the renderer when the frame finishes.",
      "*/",
    }, 60)
    assert.same({
      "/*",
      "Releases the GPU textures held by the renderer when the",
      "frame finishes.",
      "*/",
    }, out)
  end)

  it("preserves the // leader while joining", function()
    assert.same({ "// a b c d" }, format.wrap({ "// a b", "// c d" }, 20))
  end)

  it("does not join lines with different prefixes", function()
    assert.same({ "// a", "//  b" }, format.wrap({ "// a", "//  b" }, 80))
  end)

  it("keeps blank lines as paragraph breaks", function()
    assert.same({ "one two", "", "three" }, format.wrap({ "one two", "", "three" }, 80))
  end)

  it("keeps list items on their own line", function()
    assert.same({ "- item one", "* item two" }, format.wrap({ "- item one", "* item two" }, 80))
  end)

  it("treats `---` lines as standalone instead of merging them", function()
    local out = format.wrap({ "--- Doc A.", "---@param x integer" }, 20)
    assert.same({ "--- Doc A.", "---@param x integer" }, out)
  end)

  it("treats `#` lines as standalone while joining the prose after them", function()
    assert.same({ "# Title", "one two three" }, format.wrap({ "# Title", "one two", "three" }, 80))
  end)

  it("does not split words longer than the width", function()
    assert.same({ "a", "supercalifragilisticexpialidocious" }, format.wrap({ "a", "supercalifragilisticexpialidocious" }, 5))
  end)
end)

describe("docgen.format.strip_leading_name", function()
  it("drops a leading declaration name", function()
    assert.same({ "Releases textures." }, format.strip_leading_name({ "foo releases textures." }, "foo"))
  end)

  it("drops a leading name plus a following is/are", function()
    assert.same({ "A bar." }, format.strip_leading_name({ "Foo is a bar." }, "Foo"))
  end)

  it("strips the name after a comment leader", function()
    assert.same({ "--- Releases the buffer." }, format.strip_leading_name({ "--- foo releases the buffer." }, "foo"))
  end)

  it("leaves lines that do not start with the name untouched", function()
    local lines = { "Does things." }
    assert.same(lines, format.strip_leading_name(lines, "foo"))
  end)
end)

describe("docgen.format.postprocess", function()
  local languages = require("utils.docgen.languages")

  it("extracts the language's comment block and indents it", function()
    local lines, err = format.postprocess(
      languages.specs.lua,
      "Sure:\n--- Releases the buffer.\n---@param buf integer\n",
      "  ",
      {},
      {}
    )
    assert.is_nil(err)
    assert.same({ "  --- Releases the buffer.", "  ---@param buf integer" }, lines)
  end)

  it("fails when the output contains no recognizable comment block", function()
    local lines, err = format.postprocess(
      languages.specs.lua,
      "Here you go, friend: foo does stuff.\n",
      "",
      {},
      {}
    )
    assert.is_nil(lines)
    assert.truthy(err:find("no recognizable comment block"))
  end)
end)
