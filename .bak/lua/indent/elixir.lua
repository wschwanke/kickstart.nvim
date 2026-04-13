local M = {}

local bracket_types = {
  list = true,
  tuple = true,
  map = true,
  map_content = true,
  arguments = true,
}

local function is_in_bracket(lnum)
  local line = vim.fn.getline(lnum)
  local col = math.max(0, #line - 1)
  local ok, node = pcall(vim.treesitter.get_node, { pos = { lnum - 1, col } })
  if not ok or not node then return false end

  while node do
    local ntype = node:type()
    if bracket_types[ntype] then return true end
    if ntype == "do_block" or ntype == "source" then return false end
    node = node:parent()
  end
  return false
end

function M.get_indent(lnum)
  local prev_lnum = vim.fn.prevnonblank(lnum - 1)
  if prev_lnum == 0 then return 0 end

  local sw = vim.fn.shiftwidth()
  local prev_indent = vim.fn.indent(prev_lnum)

  if is_in_bracket(prev_lnum) then
    local prev_trimmed = vim.fn.trim(vim.fn.getline(prev_lnum))
    local curr_trimmed = vim.fn.trim(vim.fn.getline(lnum))

    if prev_trimmed:match('[%[{(]$') then
      return prev_indent + sw
    end

    if curr_trimmed:match('^[%]})]') then
      return math.max(0, prev_indent - sw)
    end

    return prev_indent
  end

  local ok, ts_result = pcall(function()
    return require('nvim-treesitter.indent').get_indent(lnum)
  end)
  if ok and ts_result and ts_result >= 0 then
    return ts_result
  end

  return prev_indent
end

return M
