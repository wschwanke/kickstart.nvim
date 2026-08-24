-- Treesitter helpers: locate the function under the cursor and gather the context sent to the model.
-- Everything here runs synchronously inside generate(); the HTTP callback never touches the tree.
local M = {}

---@param node TSNode
---@param bufnr integer
---@return string
function M.text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

-- Last row a node occupies. A node whose end position is column 0 of a later row
-- actually finishes on the previous row.
---@param node TSNode
---@return integer
function M.end_row(node)
  local start_row = node:start()
  local row, col = node:end_()
  if col == 0 and row > start_row then
    return row - 1
  end
  return row
end

---@param bufnr integer
---@param row integer  -- 0-based
---@return string
function M.line(bufnr, row)
  return vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
end

---@param bufnr integer
---@param row integer
---@return string
function M.line_indent(bufnr, row)
  return M.line(bufnr, row):match("^%s*") or ""
end

-- Walk previous named siblings while `pred` holds and each sibling ends on the row directly
-- above the next one (or on the same row). Returns them top-to-bottom.
---@param anchor TSNode
---@param pred fun(node: TSNode): boolean
---@return TSNode[]
function M.prev_contiguous(anchor, pred)
  local out = {}
  local cur = anchor
  while true do
    local prev = cur:prev_named_sibling()
    if not prev then
      break
    end
    local gap = cur:start() - M.end_row(prev)
    if gap > 1 or not pred(prev) then
      break
    end
    table.insert(out, 1, prev)
    cur = prev
  end
  return out
end

---@param nodes TSNode[]
---@return { start_row: integer, end_row: integer }?  -- 0-based, end exclusive
function M.rows_of(nodes)
  if #nodes == 0 then
    return nil
  end
  return { start_row = nodes[1]:start(), end_row = M.end_row(nodes[#nodes]) + 1 }
end

-- Breadth-limited search for the first node (self, children, grandchildren, ...) passing pred.
---@param node TSNode
---@param pred fun(node: TSNode): boolean
---@param depth integer
---@return TSNode?
local function find_shallow(node, pred, depth)
  if pred(node) then
    return node
  end
  if depth == 0 then
    return nil
  end
  for child in node:iter_children() do
    if child:named() then
      local hit = find_shallow(child, pred, depth - 1)
      if hit then
        return hit
      end
    end
  end
  return nil
end

---@class docgen.Target
---@field fn_node TSNode
---@field anchor TSNode
---@field name string?
---@field insert_row integer                                 -- 0-based row the doc block goes on
---@field doc_range { start_row: integer, end_row: integer }? -- existing doc rows [start, end)
---@field indent string

---@param bufnr integer
---@param spec docgen.LangSpec
---@param levels integer  -- 0 = innermost function, N = N function ancestors outward
---@return docgen.Target? target, string? err
function M.find_target(bufnr, spec, levels)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return nil, "no treesitter parser for this buffer"
  end
  parser:parse()

  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return nil, "buffer is not displayed in a window"
  end
  local cursor = vim.api.nvim_win_get_cursor(win)

  -- ignore_injections: a cursor inside a JSDoc/luadoc comment must yield the host-language node.
  local node = vim.treesitter.get_node({
    bufnr = bufnr,
    pos = { cursor[1] - 1, cursor[2] },
    ignore_injections = true,
  })
  if not node then
    return nil, "no treesitter node under cursor"
  end

  local function is_fn(n)
    return spec.is_function(n, bufnr)
  end

  local function ancestors_matching(start)
    local out, seen = {}, {}
    local cur = start
    while cur do
      if is_fn(cur) then
        local id = spec.anchor(cur, bufnr):id()
        if not seen[id] then
          seen[id] = true
          out[#out + 1] = cur
        end
      end
      cur = cur:parent()
    end
    return out
  end

  local matches = ancestors_matching(node)

  -- Cursor sitting on the existing doc comment: retarget to the function right below it.
  if #matches == 0 and spec.is_doc then
    local doc
    local cur = node
    while cur do
      if spec.is_doc(cur, bufnr) then
        doc = cur
      end
      cur = cur:parent()
    end
    if doc then
      local sib = doc:next_named_sibling()
      while sib and spec.is_doc(sib, bufnr) do
        sib = sib:next_named_sibling()
      end
      local fn = sib and find_shallow(sib, is_fn, 3)
      if fn then
        matches = ancestors_matching(fn)
      end
    end
  end

  if #matches == 0 then
    return nil, "no function under cursor"
  end

  local fn_node = matches[math.min((levels or 0) + 1, #matches)]
  local anchor = spec.anchor(fn_node, bufnr)
  local doc_range = spec.existing_doc(anchor, bufnr)
  local insert_row = doc_range and doc_range.start_row or spec.insert_row(anchor, bufnr)

  return {
    fn_node = fn_node,
    anchor = anchor,
    name = spec.fn_name and spec.fn_name(anchor, bufnr) or nil,
    insert_row = insert_row,
    doc_range = doc_range,
    indent = M.line_indent(bufnr, anchor:start()),
  }
end

---@class docgen.Context
---@field source string
---@field old_doc string?
---@field scope string[]     -- first line of each enclosing scope, outermost first
---@field imports string[]
---@field filename string
---@field filetype string

---@param bufnr integer
---@param target docgen.Target
---@param spec docgen.LangSpec
---@param cfg docgen.Config
---@return docgen.Context
function M.collect_context(bufnr, target, spec, cfg)
  local s_row, e_row = target.anchor:start(), M.end_row(target.anchor)
  if spec.source_range then
    s_row, e_row = spec.source_range(target.anchor, bufnr)
  end

  local source = {}
  for row = s_row, e_row do
    local in_doc = target.doc_range and row >= target.doc_range.start_row and row < target.doc_range.end_row
    if not in_doc then
      source[#source + 1] = M.line(bufnr, row)
    end
  end
  if #source > cfg.max_source_lines then
    source = vim.list_slice(source, 1, cfg.max_source_lines)
    source[#source + 1] = "... (truncated)"
  end

  local old_doc
  if target.doc_range then
    local lines = vim.api.nvim_buf_get_lines(bufnr, target.doc_range.start_row, target.doc_range.end_row, false)
    old_doc = table.concat(lines, "\n")
  end

  local scope = {}
  local cur = target.anchor:parent()
  while cur do
    if spec.is_scope(cur, bufnr) then
      table.insert(scope, 1, vim.trim(M.line(bufnr, cur:start())))
    end
    cur = cur:parent()
  end

  local imports = spec.imports(target.anchor:tree():root(), bufnr, target.anchor)
  if #imports > cfg.max_import_lines then
    imports = vim.list_slice(imports, 1, cfg.max_import_lines)
  end

  return {
    source = table.concat(source, "\n"),
    old_doc = old_doc,
    scope = scope,
    imports = imports,
    filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":."),
    filetype = vim.bo[bufnr].filetype,
  }
end

return M
