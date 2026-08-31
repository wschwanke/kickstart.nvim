-- Per-language knowledge: which treesitter nodes are functions, where the doc block goes,
-- what an existing doc looks like, and how the model is told to format its answer.
local ts = require("utils.docgen.treesitter")

local M = {}

---@class docgen.LangSpec
---@field name string
---@field is_function fun(node: TSNode, bufnr: integer): boolean
---@field anchor fun(node: TSNode, bufnr: integer): TSNode          -- statement the doc block goes above
---@field fn_name? fun(anchor: TSNode, bufnr: integer): string?
---@field is_scope fun(node: TSNode, bufnr: integer): boolean       -- enclosing scopes worth showing the model
---@field is_doc? fun(node: TSNode, bufnr: integer): boolean        -- node counts as documentation/attribute
---@field imports fun(root: TSNode, bufnr: integer, anchor: TSNode): string[]
---@field existing_doc fun(anchor: TSNode, bufnr: integer): { start_row: integer, end_row: integer }?
---@field insert_row fun(anchor: TSNode, bufnr: integer): integer
---@field source_range? fun(anchor: TSNode, bufnr: integer): integer, integer  -- inclusive rows
---@field placeholder fun(text: string): string[]
---@field extract fun(lines: string[], cfg: docgen.Config, ctx: docgen.Context): string[]?  -- only provable comment lines
---@field system_prompt string|fun(cfg: docgen.Config, ctx: docgen.Context): string
---@field wrap? boolean  -- reflow inserted prose to 'textwidth'; only understands `//` leaders, so
---                       -- only enable for leader-less (Odin `/* */`) or `//`-commented languages
---@field finalize? fun(lines: string[], ctx: docgen.Context, cfg: docgen.Config): string[]  -- last pass over the indented, wrapped lines

local text = ts.text

-- Shared anti-narration rule. format.lua also repeats it (as the litmus test) in the user message
-- right after the declaration, so keep this one short.
local NO_NARRATION = "Write only sentences that stay true if the body were reimplemented differently; no step-by-step narration."

-- Shared anti-restatement rule for @param/## Parameters/---@param lines.
local PARAM_RULE = "In parameter descriptions, say what the value means or constrains; never merely restate the name or type."

---@param node TSNode
---@param name string
---@return TSNode?
local function field(node, name)
  return node:field(name)[1]
end

---@param node TSNode
---@param t string
---@return TSNode?
local function child_of_type(node, t)
  for child in node:iter_children() do
    if child:type() == t then
      return child
    end
  end
  return nil
end

local function type_in(set)
  return function(node)
    return set[node:type()] == true
  end
end

local function set_of(list)
  local out = {}
  for _, v in ipairs(list) do
    out[v] = true
  end
  return out
end

-- Root-level children whose text starts with one of the given keywords -> their first line.
local function root_lines_starting_with(root, bufnr, keywords)
  local out = {}
  for child in root:iter_children() do
    if child:named() then
      local line = vim.trim(ts.line(bufnr, child:start()))
      for _, kw in ipairs(keywords) do
        if line:sub(1, #kw) == kw then
          out[#out + 1] = line
          break
        end
      end
    end
  end
  return out
end

-- Leading run of lines matching `pattern`, starting at the first match.
local function extract_run(lines, pattern)
  local first
  for i, l in ipairs(lines) do
    if l:match(pattern) then
      first = i
      break
    end
  end
  if not first then
    return nil
  end
  local last = first
  while lines[last + 1] and lines[last + 1]:match(pattern) do
    last = last + 1
  end
  return vim.list_slice(lines, first, last)
end

-- Block from the first line matching `open` through the first following line matching `close`.
local function extract_block(lines, open, close)
  local first
  for i, l in ipairs(lines) do
    if l:match(open) then
      first = i
      break
    end
  end
  if not first then
    return nil
  end
  for j = first, #lines do
    if lines[j]:match(close) then
      return vim.list_slice(lines, first, j)
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- JavaScript / TypeScript (shared ecma grammar shapes)
-- ---------------------------------------------------------------------------

local JS_FN = set_of({
  "function_declaration",
  "generator_function_declaration",
  "method_definition",
  "function_signature",
  "method_signature",
  "abstract_method_signature",
})
local JS_FN_VALUE = set_of({ "arrow_function", "function_expression", "generator_function" })
local JS_HOLDER = { variable_declarator = "value", pair = "value", public_field_definition = "value", assignment_expression = "right" }
local JS_CLIMB = set_of({ "lexical_declaration", "variable_declaration", "export_statement", "expression_statement" })

local function js_is_function(node)
  local t = node:type()
  if JS_FN[t] then
    return true
  end
  local value_field = JS_HOLDER[t]
  if value_field then
    local value = field(node, value_field)
    return value ~= nil and JS_FN_VALUE[value:type()] == true
  end
  if t == "export_statement" then
    -- `export default () => {}`
    local value = field(node, "value")
    return value ~= nil and JS_FN_VALUE[value:type()] == true
  end
  return false
end

local function js_anchor(node)
  local cur = node
  while true do
    local parent = cur:parent()
    if not parent or not JS_CLIMB[parent:type()] then
      return cur
    end
    cur = parent
  end
end

local function js_name(node, bufnr)
  local t = node:type()
  if t == "export_statement" then
    local inner = field(node, "declaration") or field(node, "value")
    return inner and js_name(inner, bufnr) or nil
  elseif t == "lexical_declaration" or t == "variable_declaration" or t == "expression_statement" then
    local inner = node:named_child(0)
    return inner and js_name(inner, bufnr) or nil
  elseif t == "assignment_expression" then
    local left = field(node, "left")
    return left and text(left, bufnr) or nil
  elseif t == "pair" then
    local key = field(node, "key")
    return key and text(key, bufnr) or nil
  end
  local name = field(node, "name")
  return name and text(name, bufnr) or nil
end

-- Class-method decorators are *siblings* preceding the method; step above them.
local function js_top(anchor)
  local cur = anchor
  while true do
    local prev = cur:prev_named_sibling()
    if not prev or prev:type() ~= "decorator" or cur:start() - ts.end_row(prev) > 1 then
      return cur
    end
    cur = prev
  end
end

local function js_existing_doc(anchor, bufnr)
  local run = ts.prev_contiguous(js_top(anchor), type_in({ comment = true }))
  for i = #run, 1, -1 do
    if text(run[i], bufnr):match("^/%*%*") then
      return ts.rows_of({ run[i] })
    end
  end
  return nil
end

local javascript = {
  name = "javascript",
  is_function = js_is_function,
  anchor = js_anchor,
  fn_name = js_name,
  is_scope = type_in(set_of({
    "class_declaration",
    "abstract_class_declaration",
    "class",
    "interface_declaration",
    "function_declaration",
    "generator_function_declaration",
    "method_definition",
    "arrow_function",
    "function_expression",
  })),
  is_doc = type_in({ comment = true, decorator = true }),
  imports = function(root, bufnr)
    local out = root_lines_starting_with(root, bufnr, { "import ", "import{", "export * from", "export {" })
    for child in root:iter_children() do
      if child:named() and text(child, bufnr):match("require%(") then
        out[#out + 1] = vim.trim(ts.line(bufnr, child:start()))
      end
    end
    return out
  end,
  existing_doc = js_existing_doc,
  insert_row = function(anchor)
    return js_top(anchor):start()
  end,
  placeholder = function(t)
    return { "/** " .. t .. " */" }
  end,
  extract = function(lines)
    return extract_block(lines, "^%s*/%*%*", "%*/%s*$")
  end,
  system_prompt = table.concat({
    "Language: JavaScript. Write a JSDoc block comment (`/** ... */`, each inner line starting with ` * `).",
    "Start with a one-line summary of what the function accomplishes and why a caller would use it, then",
    "a blank ` *` line and only the details a caller needs: semantics, side effects, invariants.",
    NO_NARRATION,
    "Add `@param {type} name - description` for every parameter (infer types from usage; use `[name]` for",
    "optional and `{...type}` for rest parameters), `@returns {type} description` unless the function returns",
    "nothing, `@throws` when the function throws, `@template` for generics, and `@async` is NOT needed.",
    PARAM_RULE,
    "Do not repeat the function signature or the code.",
  }, " "),
}

local typescript = vim.tbl_extend("force", javascript, {
  name = "typescript",
  system_prompt = table.concat({
    "Language: TypeScript. Write a TSDoc/JSDoc block comment (`/** ... */`, each inner line starting with ` * `).",
    "Start with a one-line summary of what the function accomplishes and why a caller would use it, then",
    "a blank ` *` line and only the details a caller needs: semantics, side effects, invariants.",
    NO_NARRATION,
    "Add `@param name - description` for every parameter and `@returns description` unless it returns void.",
    "Do NOT include `{type}` braces: the TypeScript annotations already carry the types.",
    "Use `@typeParam T - description` for generics and `@throws` when relevant.",
    PARAM_RULE,
    "Do not repeat the function signature or the code.",
  }, " "),
})

-- ---------------------------------------------------------------------------
-- Elixir
-- ---------------------------------------------------------------------------

local EX_DEF = set_of({ "def", "defp", "defmacro", "defmacrop", "defguard", "defguardp", "defdelegate" })
local EX_MODULE = set_of({ "defmodule", "defprotocol", "defimpl" })
local EX_IMPORT = set_of({ "use", "alias", "import", "require" })

local function ex_target(node, bufnr)
  if node:type() ~= "call" then
    return nil
  end
  local target = field(node, "target")
  if not target or target:type() ~= "identifier" then
    return nil
  end
  return text(target, bufnr)
end

local function ex_is_def(node, bufnr)
  local target = ex_target(node, bufnr)
  return target ~= nil and EX_DEF[target] == true
end

-- `@name ...` module attribute -> "name"
local function ex_attr(node, bufnr)
  if node:type() ~= "unary_operator" or text(node, bufnr):sub(1, 1) ~= "@" then
    return nil
  end
  local operand = field(node, "operand")
  if not operand or operand:type() ~= "call" then
    return nil
  end
  return ex_target(operand, bufnr)
end

local function ex_def_name(call, bufnr)
  local args = child_of_type(call, "arguments") -- `arguments` is a plain child here, not a field
  local head = args and args:named_child(0)
  if not head then
    return nil
  end
  if head:type() == "binary_operator" then -- `def f(x) when guard`
    head = field(head, "left")
  end
  if not head then
    return nil
  end
  if head:type() == "call" then
    local target = field(head, "target")
    return target and text(target, bufnr) or nil
  elseif head:type() == "identifier" then
    return text(head, bufnr)
  end
  return nil
end

-- First clause of the function: walk back over sibling clauses with the same name and any
-- attributes/comments sitting between them.
local function ex_anchor(call, bufnr)
  local name = ex_def_name(call, bufnr)
  local first, cur = call, call
  while true do
    local prev = cur:prev_named_sibling()
    if not prev then
      break
    end
    if ex_is_def(prev, bufnr) then
      if ex_def_name(prev, bufnr) ~= name then
        break
      end
      first = prev
    elseif not ex_attr(prev, bufnr) and prev:type() ~= "comment" then
      break
    end
    cur = prev
  end
  return first
end

-- Topmost attribute (@spec, @impl, ...) directly above the first clause, excluding @doc itself.
local function ex_top(anchor, bufnr)
  local cur = anchor
  while true do
    local prev = cur:prev_named_sibling()
    if not prev or cur:start() - ts.end_row(prev) > 1 then
      return cur
    end
    local attr = ex_attr(prev, bufnr)
    if not attr or attr == "doc" then
      return cur
    end
    cur = prev
  end
end

local elixir = {
  name = "elixir",
  is_function = ex_is_def,
  anchor = ex_anchor,
  fn_name = ex_def_name,
  is_scope = function(node, bufnr)
    local target = ex_target(node, bufnr)
    return target ~= nil and EX_MODULE[target] == true
  end,
  is_doc = function(node, bufnr)
    return node:type() == "comment" or ex_attr(node, bufnr) ~= nil
  end,
  imports = function(root, bufnr, anchor)
    local out = {}
    local function scan(parent)
      for child in parent:iter_children() do
        local target = ex_target(child, bufnr)
        if target and EX_IMPORT[target] then
          out[#out + 1] = vim.trim(ts.line(bufnr, child:start()))
        end
      end
    end
    scan(root)
    local cur = anchor:parent()
    while cur do
      local target = ex_target(cur, bufnr)
      if target and EX_MODULE[target] then
        local body = cur:named_child(cur:named_child_count() - 1)
        if body and body:type() == "do_block" then
          scan(body)
        end
      end
      cur = cur:parent()
    end
    return out
  end,
  existing_doc = function(anchor, bufnr)
    local cur = anchor
    while true do
      local prev = cur:prev_named_sibling()
      if not prev or cur:start() - ts.end_row(prev) > 1 then
        return nil
      end
      local attr = ex_attr(prev, bufnr)
      if attr == "doc" then
        return ts.rows_of({ prev })
      elseif not attr and prev:type() ~= "comment" then
        return nil
      end
      cur = prev
    end
  end,
  insert_row = function(anchor, bufnr)
    return ex_top(anchor, bufnr):start()
  end,
  source_range = function(anchor, bufnr)
    local name = ex_def_name(anchor, bufnr)
    local last, cur = anchor, anchor
    while true do
      local nxt = cur:next_named_sibling()
      if not nxt then
        break
      end
      if ex_is_def(nxt, bufnr) then
        if ex_def_name(nxt, bufnr) ~= name then
          break
        end
        last = nxt
      elseif not ex_attr(nxt, bufnr) and nxt:type() ~= "comment" then
        break
      end
      cur = nxt
    end
    return ex_top(anchor, bufnr):start(), ts.end_row(last)
  end,
  placeholder = function(t)
    return { "# " .. t }
  end,
  extract = function(lines, cfg, ctx)
    local first
    for i, l in ipairs(lines) do
      if l:match("^%s*@doc%s") then
        first = i
        break
      end
    end
    if not first then
      return nil
    end
    local last = first
    local _, quotes = lines[first]:gsub('"""', "")
    if quotes == 1 then -- heredoc opened on this line; find the closing """
      last = nil
      for j = first + 1, #lines do
        if lines[j]:match('^%s*"""%s*$') then
          last = j
          break
        end
      end
      if not last then
        return nil
      end
    end
    local want_spec = cfg.elixir.spec and not ctx.source:match("@spec%s")
    while want_spec and lines[last + 1] and lines[last + 1]:match("^%s*@spec%s") do
      last = last + 1
    end
    return vim.list_slice(lines, first, last)
  end,
  system_prompt = function(cfg, ctx)
    local spec_rule
    if cfg.elixir.spec and not ctx.source:match("@spec%s") then -- keep in sync with extract above
      spec_rule = 'After the closing """ line, add a single `@spec name(arg_types) :: return_type` line.'
    else
      spec_rule = "Do NOT emit an @spec."
    end
    return table.concat({
      'Language: Elixir. Write a module attribute doc block: `@doc """` on its own line, the documentation,',
      'then `"""` on its own line. Begin with a one-sentence summary of what the function accomplishes for',
      "its caller, a blank line, then only the details a caller needs. " .. NO_NARRATION,
      "Add `## Parameters` (as `- name - description` bullets) when the parameters need explanation and",
      "`## Examples` with `iex>` doctests when a short, obviously-correct example exists.",
      PARAM_RULE,
      "If several clauses are shown, document the function once as a whole.",
      spec_rule,
      "Do not repeat the code.",
    }, " ")
  end,
}

-- ---------------------------------------------------------------------------
-- Odin
-- ---------------------------------------------------------------------------

local ODIN_COMMENT = set_of({ "comment", "block_comment" })

-- Declarations that get a doc block anywhere they appear...
local ODIN_DECL = set_of({ "procedure_declaration", "struct_declaration", "enum_declaration", "union_declaration" })
-- ...and ones that only count at file scope, so a cursor on a local `x := 1` still documents the proc.
local ODIN_TOP_DECL = set_of({ "const_declaration", "var_declaration", "variable_declaration" })

local odin = {
  name = "odin",
  is_function = function(node)
    local t = node:type()
    if ODIN_DECL[t] then
      return true
    end
    local parent = node:parent()
    return ODIN_TOP_DECL[t] and parent ~= nil and parent:type() == "source_file"
  end,
  anchor = function(node)
    return node
  end,
  fn_name = function(anchor, bufnr)
    for child in anchor:iter_children() do
      if child:type() == "identifier" then
        return text(child, bufnr)
      end
    end
    return nil
  end,
  is_scope = type_in({ procedure_declaration = true }),
  is_doc = type_in(ODIN_COMMENT),
  imports = function(root, bufnr)
    return root_lines_starting_with(root, bufnr, { "package ", "import " })
  end,
  existing_doc = function(anchor)
    return ts.rows_of(ts.prev_contiguous(anchor, type_in(ODIN_COMMENT)))
  end,
  insert_row = function(anchor)
    return (anchor:start()) -- attributes are children, so this row is already above `@(...)`
  end,
  placeholder = function(t)
    return { "/* " .. t .. " */" }
  end,
  extract = function(lines)
    return extract_block(lines, "^%s*/%*", "%*/%s*$") or extract_run(lines, "^%s*//")
  end,
  wrap = true,
  -- A constant/variable whose whole description fits on one line gets `// text` instead of a
  -- three-line block. Multi-line descriptions and all other declarations keep the block.
  finalize = function(lines, ctx)
    if not ODIN_TOP_DECL[ctx.kind] then
      return lines
    end
    local indent = lines[1]:match("^%s*")
    local text
    if #lines == 1 then
      text = lines[1]:match("^%s*/%*%s*(.-)%s*%*/%s*$")
    elseif #lines == 3 and lines[1]:match("^%s*/%*%s*$") and lines[3]:match("^%s*%*/%s*$") then
      text = vim.trim(lines[2])
    end
    if not text or text == "" or text:find("\n") then
      return lines
    end
    return { indent .. "// " .. text }
  end,
  system_prompt = table.concat({
    "Language: Odin. Write a block comment in the style of the Odin core library: `/*` on its own line,",
    "then a plain-prose description, then `*/` on its own line. The declaration may be a procedure",
    "(describe what it does), a struct/enum/union (describe what it represents and how it is used),",
    "or a constant/variable (describe what it holds and what it is for).",
    "Start with a one-sentence summary; add further sentences only when needed to explain behavior,",
    "side effects, allocation/ownership, or error conditions. " .. NO_NARRATION,
    "Be concise, not wordy.",
    "Write flowing prose as a single paragraph and never insert manual line breaks (lines are wrapped",
    "automatically); only a genuinely separate point may go in a second paragraph after a blank line.",
    "Never begin with the declaration's name: write `Releases the GPU textures held by the renderer.`,",
    "not `destroy_textures releases ...`.",
    "Do NOT include `Inputs:`, `Returns:`, parameter or field lists, or any other structured sections.",
    "Content lines inside the block are not indented. Do not repeat the code.",
  }, " "),
}

-- ---------------------------------------------------------------------------
-- Lua
-- ---------------------------------------------------------------------------

local function lua_is_function(node)
  local t = node:type()
  if t == "function_declaration" then
    return true
  end
  if t ~= "function_definition" then
    return false
  end
  local parent = node:parent()
  if not parent then
    return false
  end
  local pt = parent:type()
  return pt == "field" or (pt == "expression_list" and parent:parent() ~= nil and parent:parent():type() == "assignment_statement")
end

local LUA_CLIMB = set_of({ "expression_list", "assignment_statement", "variable_declaration" })

local function lua_anchor(node)
  if node:type() ~= "function_definition" then
    return node
  end
  local parent = node:parent()
  if parent and parent:type() == "field" then
    return parent
  end
  local cur = node
  while true do
    local up = cur:parent()
    if not up or not LUA_CLIMB[up:type()] then
      return cur
    end
    cur = up
  end
end

local lua = {
  name = "lua",
  is_function = lua_is_function,
  anchor = lua_anchor,
  fn_name = function(anchor, bufnr)
    local t = anchor:type()
    if t == "function_declaration" or t == "field" then
      local name = field(anchor, "name")
      return name and text(name, bufnr) or nil
    end
    local assign = t == "assignment_statement" and anchor or anchor:named_child(0)
    if not assign or assign:type() ~= "assignment_statement" then
      return nil
    end
    local vars = assign:named_child(0)
    local name = vars and vars:named_child(0)
    return name and text(name, bufnr) or nil
  end,
  is_scope = type_in({ function_declaration = true, function_definition = true }),
  is_doc = type_in({ comment = true }),
  imports = function(root, bufnr)
    local out = {}
    for child in root:iter_children() do
      if child:named() then
        local line = ts.line(bufnr, child:start())
        if line:match("require%s*[%(\"']") then
          out[#out + 1] = vim.trim(line)
        end
      end
    end
    return out
  end,
  existing_doc = function(anchor)
    return ts.rows_of(ts.prev_contiguous(anchor, type_in({ comment = true })))
  end,
  insert_row = function(anchor)
    return (anchor:start())
  end,
  placeholder = function(t)
    return { "--- " .. t }
  end,
  extract = function(lines)
    return extract_run(lines, "^%s*%-%-")
  end,
  system_prompt = table.concat({
    "Language: Lua. Write LuaCATS (EmmyLua-style) annotations. Every line starts with `---`.",
    "First a `--- summary` line stating what the function accomplishes for its caller, then `---@param name type description`",
    "for each parameter (use `name?` for optional ones and `...` for varargs), `---@return type description`",
    "for each return value, and `---@generic T` when needed. Infer types from usage; use `any` if unclear.",
    PARAM_RULE,
    "Additional `---` prose lines are only for behavior a caller must know (side effects, errors,",
    "invariants). " .. NO_NARRATION,
    "Do not repeat the code.",
  }, " "),
}

-- ---------------------------------------------------------------------------
-- Generic fallback: nvim-treesitter-textobjects' @function.outer + 'commentstring'
-- ---------------------------------------------------------------------------

---@param bufnr integer
---@return docgen.LangSpec?, string?
function M.generic(bufnr)
  local ft = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok, query = pcall(vim.treesitter.query.get, lang, "textobjects")
  if not ok or not query then
    return nil, ("docgen has no template for %s and no treesitter function query was found"):format(ft)
  end

  local cs = vim.bo[bufnr].commentstring
  if cs == nil or cs == "" or not cs:find("%%s") then
    cs = "# %s"
  end
  local left, right = cs:match("^(.-)%%s(.*)$")
  left, right = vim.trim(left), vim.trim(right)
  local left_pat = "^%s*" .. vim.pesc(left)
  local block = right ~= ""

  local function is_function(node)
    local root = node:tree():root()
    local s_row, _, e_row = node:range()
    for id, captured in query:iter_captures(root, bufnr, s_row, e_row + 1) do
      if query.captures[id] == "function.outer" and captured:id() == node:id() then
        return true
      end
    end
    return false
  end

  return {
    name = ft,
    is_function = is_function,
    anchor = function(node)
      return node
    end,
    fn_name = function(anchor, bufnr2)
      local name = field(anchor, "name")
      return name and text(name, bufnr2) or nil
    end,
    is_scope = function(node)
      local t = node:type()
      return t:find("class") ~= nil or t:find("struct") ~= nil or t:find("impl") ~= nil or t:find("module") ~= nil
    end,
    is_doc = function(node)
      return node:type():find("comment") ~= nil
    end,
    imports = function(root, bufnr2)
      local out = {}
      for child in root:iter_children() do
        local t = child:type()
        if child:named() and (t:find("import") or t:find("use") or t:find("include") or t:find("package")) then
          out[#out + 1] = vim.trim(ts.line(bufnr2, child:start()))
        end
      end
      return out
    end,
    existing_doc = function(anchor)
      return ts.rows_of(ts.prev_contiguous(anchor, function(n)
        return n:type():find("comment") ~= nil
      end))
    end,
    insert_row = function(anchor)
      return (anchor:start())
    end,
    placeholder = function(t)
      return { (cs:format(t)) }
    end,
    extract = function(lines)
      if block then
        return extract_block(lines, left_pat, vim.pesc(right) .. "%s*$")
      end
      return extract_run(lines, left_pat)
    end,
    system_prompt = block
        and ("Language: %s. Write a documentation comment that starts with `%s` and ends with `%s`: a one-line summary of what it accomplishes for its caller, then the parameters and return value in prose or the language's conventional doc style. %s Do not repeat the code."):format(
          ft,
          left,
          right,
          NO_NARRATION
        )
      or ("Language: %s. Write a documentation comment where EVERY line begins with `%s`: a one-line summary of what it accomplishes for its caller, then the parameters and return value in the language's conventional doc style. %s Do not repeat the code."):format(
        ft,
        left,
        NO_NARRATION
      ),
  }
end

M.specs = {
  javascript = javascript,
  typescript = typescript,
  elixir = elixir,
  odin = odin,
  lua = lua,
}

M.ft_to_spec = {
  javascript = "javascript",
  javascriptreact = "javascript",
  typescript = "typescript",
  typescriptreact = "typescript",
  elixir = "elixir",
  odin = "odin",
  lua = "lua",
}

---@param bufnr integer
---@param cfg docgen.Config
---@return docgen.LangSpec?, string?
function M.get(bufnr, cfg)
  local ft = vim.bo[bufnr].filetype
  local key = M.ft_to_spec[ft]
  local spec, err
  if key then
    spec = M.specs[key]
  else
    spec, err = M.generic(bufnr)
  end
  if not spec then
    return nil, err
  end
  local override = cfg and cfg.languages and cfg.languages[ft]
  if override then
    spec = vim.tbl_extend("force", spec, override)
  end
  return spec
end

return M
