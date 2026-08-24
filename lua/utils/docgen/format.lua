-- Prompt construction and post-processing of the model's reply.
local M = {}

local BASE_PROMPT = table.concat({
  "You write documentation comments for source code.",
  "Respond with ONLY the finished documentation comment block for the given function, in the exact style",
  "described below. Output no code, no markdown fences, and no prose before or after the comment.",
  "Keep the documentation accurate to the code shown. If existing documentation is provided, improve and",
  "correct it rather than starting over, keeping whatever is still accurate.",
}, " ")

---@param spec docgen.LangSpec
---@param ctx docgen.Context
---@param cfg docgen.Config
---@return string system, string user
function M.build_prompt(spec, ctx, cfg)
  local fragment = spec.system_prompt
  if type(fragment) == "function" then
    fragment = fragment(cfg, ctx)
  end
  local system = BASE_PROMPT .. "\n\n" .. fragment

  local parts = { ("File: %s (%s)"):format(ctx.filename, ctx.filetype) }
  if #ctx.imports > 0 then
    parts[#parts + 1] = "Imports:\n" .. table.concat(ctx.imports, "\n")
  end
  if #ctx.scope > 0 then
    parts[#parts + 1] = "Enclosing scope (outermost first):\n" .. table.concat(ctx.scope, "\n")
  end
  if ctx.old_doc and ctx.old_doc ~= "" then
    parts[#parts + 1] = "Existing documentation (improve it; keep what is still correct):\n" .. ctx.old_doc
  end
  parts[#parts + 1] = "Function to document:\n" .. ctx.source

  return system, table.concat(parts, "\n\n")
end

-- Split into lines, trim trailing whitespace, drop surrounding blank lines and, if the model
-- wrapped its answer in a ``` fence anywhere, keep only what is inside the first fence pair.
---@param text string
---@return string[]
function M.strip_fences(text)
  local lines = vim.split(text, "\n", { plain = true })
  for i, l in ipairs(lines) do
    lines[i] = (l:gsub("%s+$", ""))
  end

  local open, close
  for i, l in ipairs(lines) do
    if l:match("^%s*```") then
      if not open then
        open = i
      elseif not close then
        close = i
        break
      end
    end
  end
  if open then
    lines = vim.list_slice(lines, open + 1, close and (close - 1) or #lines)
  end

  while lines[1] and lines[1] == "" do
    table.remove(lines, 1)
  end
  while lines[#lines] and lines[#lines] == "" do
    table.remove(lines)
  end
  return lines
end

-- Remove the common leading whitespace of all non-blank lines.
---@param lines string[]
---@return string[]
function M.dedent(lines)
  local min
  for _, l in ipairs(lines) do
    if l ~= "" then
      local n = #l:match("^%s*")
      if not min or n < min then
        min = n
      end
    end
  end
  if not min or min == 0 then
    return lines
  end
  return vim.tbl_map(function(l)
    return l == "" and "" or l:sub(min + 1)
  end, lines)
end

---@param spec docgen.LangSpec
---@param raw string
---@param indent string
---@param cfg docgen.Config
---@param ctx docgen.Context
---@return string[]? lines, string? err
function M.postprocess(spec, raw, indent, cfg, ctx)
  local lines = M.strip_fences(raw)
  local block = spec.extract(lines, cfg, ctx)
  if not block or #block == 0 then
    return nil, "model output contained no recognizable comment block"
  end
  block = M.dedent(block)
  for i, l in ipairs(block) do
    if l ~= "" then
      block[i] = indent .. l
    end
  end
  return block
end

return M
