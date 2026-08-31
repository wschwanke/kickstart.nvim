-- Prompt construction and post-processing of the model's reply.
local M = {}

local BASE_PROMPT = table.concat({
  "You write documentation comments for source code.",
  "Respond with ONLY the finished documentation comment block for the given declaration (a function,",
  "type, constant, or variable), in the exact style",
  "described below. Output no code, no markdown fences, and no prose before or after the comment.",
  "The litmus test: every sentence you write must stay true if the body were reimplemented with a",
  "completely different algorithm. Describe what the declaration is for and what a caller can rely on",
  "(behavior, arguments, return value, side effects, error conditions); a reader who can already read",
  "the implementation learns nothing from narration of it.",
  "Before answering, check each sentence against the litmus test and rewrite or delete any that fail.",
  "Sentences that fail mention control flow (first... then... finally...), loop/collection mechanics",
  "(iterates, appends, decrements), or identifiers that appear only inside the body.",
  "Contrast: BAD -- `Opens the file, sets the encoding, reads line by line, then closes the handle.`",
  "GOOD -- `Reads the whole file as UTF-8 and returns its lines.` The good one says what the caller gets,",
  "not how the machine gets it.",
  "The same litmus test applies to parameter and return descriptions: BAD -- `@param buf - the buffer",
  "number` GOOD -- `@param buf - buffer whose lines are read`. A description that merely restates the",
  "name or type is worthless; say what the value means or constrains.",
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
  parts[#parts + 1] = "Declaration to document:\n" .. ctx.source
  -- Last thing the model reads: recency beats the system prompt, so the anti-narration rule
  -- must sit directly after the code it is tempted to paraphrase.
  parts[#parts + 1] = table.concat({
    "Document the declaration above at the caller's level of abstraction. Each sentence must stay true",
    "if the body were reimplemented differently -- so: no first/then/finally steps, no loop or",
    "collection mechanics, no body-only identifiers. Say what the caller gets and can rely on.",
  }, " ")

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

--- Reflow prose to `width`: consecutive non-blank lines with the same indent (and `//` leader) are
--- joined into one paragraph and re-wrapped at word boundaries, so the model's own line breaks are
--- discarded. Blank lines, `/*` / `*/` delimiter lines, list items, and `--` / `#` comment lines
--- keep their own line, so a deliberate paragraph break survives. Only `//` leaders are reflowed;
--- enabling `wrap` for a language whose comment lines start differently (e.g. Lua's `---`) is
--- safe but inert: those lines pass through verbatim instead of being merged.
---@param lines string[]
---@param width integer  -- 0 falls back to 79, matching Vim's own behaviour for 'textwidth'
---@return string[]
function M.wrap(lines, width)
  if width <= 0 then
    width = 79
  end

  ---@param prefix string
  ---@param words string[]
  ---@param out string[]
  local function emit(prefix, words, out)
    local pw = vim.fn.strdisplaywidth(prefix)
    local cur
    for _, word in ipairs(words) do
      if not cur then
        cur = word
      elseif pw + vim.fn.strdisplaywidth(cur .. " " .. word) <= width then
        cur = cur .. " " .. word
      else
        out[#out + 1] = prefix .. cur
        cur = word
      end
    end
    if cur then
      out[#out + 1] = prefix .. cur
    end
  end

  local out, prefix, words = {}, nil, {}
  local function flush()
    if prefix then
      emit(prefix, words, out)
    end
    prefix, words = nil, {}
  end

  for _, line in ipairs(lines) do
    local indent, content = line:match("^(%s*)(.-)%s*$")
    local leader = content:match("^//+%s*") or ""
    local body = content:sub(#leader + 1)
    local standalone = body == "" or body:match("^/%*") or body:match("%*/$") or body:match("^[-*] ")
      or body:match("^%-%-") or body:match("^#")
    if standalone then
      flush()
      out[#out + 1] = line
    else
      local p = indent .. leader
      if prefix and p ~= prefix then
        flush()
      end
      prefix = p
      for word in body:gmatch("%S+") do
        words[#words + 1] = word
      end
    end
  end
  flush()
  return out
end

--- Models like to open with "`name` does X" / "`name` is a Y" even when told not to. If one of the
--- first two lines starts (after any comment leader) with `name` followed by a space, drop the name
--- (and a following "is"/"are") and capitalise what follows, so "foo releases the ..." becomes
--- "Releases the ..." and "Foo is a bar." becomes "A bar.".
---@param lines string[]
---@param name string?
---@return string[]
function M.strip_leading_name(lines, name)
  if not name or name == "" then
    return lines
  end
  local pat = "^(%s*[/%*%-#]*%s*)" .. vim.pesc(name) .. "%s+(.*)$"
  for i = 1, math.min(2, #lines) do
    local prefix, rest = lines[i]:match(pat)
    if prefix then
      rest = rest:gsub("^[Ii]s%s+", ""):gsub("^[Aa]re%s+", "")
      if rest ~= "" then
        lines[i] = prefix .. rest:sub(1, 1):upper() .. rest:sub(2)
        break
      end
    end
  end
  return lines
end

return M
