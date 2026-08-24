-- docgen: generate a documentation comment for the function under the cursor with an LLM
-- (OpenRouter) and insert it in the language's native doc syntax. Replaces neogen.
--
--   require("utils.docgen").generate()      -- or TeamoXtremo.util.docgen.generate()
--   :DocGen [count]   :DocModel[!]   :DocGenCancel
local format = require("utils.docgen.format")
local languages = require("utils.docgen.languages")
local openrouter = require("utils.docgen.openrouter")
local ts = require("utils.docgen.treesitter")

local M = {}

---@class docgen.Config
---@field model? string                 -- fallback when nothing has been picked with :DocModel
---@field timeout_ms integer
---@field max_tokens integer
---@field temperature number
---@field placeholder_text string
---@field site_url? string              -- HTTP-Referer header (OpenRouter attribution, optional)
---@field app_name? string              -- X-Title header
---@field elixir { spec: boolean }      -- also generate @spec when the function has none
---@field languages table<string, table> -- per-filetype overrides merged over languages.lua specs
---@field max_source_lines integer
---@field max_import_lines integer
---@field models_cache_ttl_s integer
---@field notify_title string

local defaults = {
  model = nil,
  timeout_ms = 30000,
  max_tokens = 1024,
  temperature = 0.2,
  placeholder_text = "Generating docs...",
  site_url = nil,
  app_name = "nvim-docgen",
  elixir = { spec = false },
  languages = {},
  max_source_lines = 400,
  max_import_lines = 40,
  models_cache_ttl_s = 86400,
  notify_title = "docgen",
}

---@type docgen.Config
M.config = vim.deepcopy(defaults)

local ns = vim.api.nvim_create_namespace("docgen")

---@class docgen.Request
---@field buf integer
---@field mark integer
---@field old_lines string[]
---@field placeholder string[]
---@field indent string
---@field spec docgen.LangSpec
---@field ctx docgen.Context
---@field name string?
---@field changedtick integer
---@field proc vim.SystemObj?
---@field cancelled boolean

---@type table<string, docgen.Request>
local requests = {}

local function key_of(buf, mark)
  return buf .. ":" .. mark
end

---@param msg string
---@param level? integer
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = M.config.notify_title })
end

---@param opts? docgen.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  vim.api.nvim_create_autocmd("BufUnload", {
    group = vim.api.nvim_create_augroup("docgen", { clear = true }),
    callback = function(ev)
      M.cancel(ev.buf, { restore = false })
    end,
  })
end

---@return string?
function M.get_model()
  local saved = openrouter.load_model()
  return saved and saved.model or M.config.model
end

-- ---------------------------------------------------------------------------
-- Placeholder bookkeeping
-- ---------------------------------------------------------------------------

-- Row of the placeholder if it is still intact, nil if the user removed or edited it.
---@param req docgen.Request
---@return integer?
local function placeholder_row(req)
  if not vim.api.nvim_buf_is_valid(req.buf) or not vim.api.nvim_buf_is_loaded(req.buf) then
    return nil
  end
  local pos = vim.api.nvim_buf_get_extmark_by_id(req.buf, ns, req.mark, {})
  if #pos == 0 then
    return nil
  end
  local row = pos[1]
  local current = vim.api.nvim_buf_get_lines(req.buf, row, row + #req.placeholder, false)
  if not vim.deep_equal(current, req.placeholder) then
    return nil
  end
  return row
end

---@param req docgen.Request
---@param row integer
---@param lines string[]
local function replace_placeholder(req, row, lines)
  vim.api.nvim_buf_call(req.buf, function()
    -- Fold into the placeholder's undo step only if nothing else changed in between.
    if vim.api.nvim_buf_get_changedtick(req.buf) == req.changedtick then
      pcall(vim.cmd, "silent! undojoin")
    end
    vim.api.nvim_buf_set_lines(req.buf, row, row + #req.placeholder, false, lines)
  end)
end

---@param req docgen.Request
local function release(req)
  requests[key_of(req.buf, req.mark)] = nil
  if vim.api.nvim_buf_is_valid(req.buf) then
    pcall(vim.api.nvim_buf_del_extmark, req.buf, ns, req.mark)
  end
end

---@param req docgen.Request
---@param restore boolean
local function cancel_request(req, restore)
  req.cancelled = true
  if req.proc then
    pcall(req.proc.kill, req.proc, 15)
  end
  if restore then
    local row = placeholder_row(req)
    if row then
      replace_placeholder(req, row, req.old_lines)
    end
  end
  release(req)
end

---@param buf integer
---@param row integer
---@return docgen.Request?
local function request_at(buf, row)
  for _, req in pairs(requests) do
    if req.buf == buf and placeholder_row(req) == row then
      return req
    end
  end
  return nil
end

---@param bufnr? integer  -- nil = every buffer
---@param opts? { restore?: boolean }
function M.cancel(bufnr, opts)
  local restore = not (opts and opts.restore == false)
  for _, req in pairs(vim.tbl_values(requests)) do -- snapshot: cancel_request mutates `requests`
    if not bufnr or req.buf == bufnr then
      cancel_request(req, restore)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Response handling
-- ---------------------------------------------------------------------------

---@param req docgen.Request
---@param err string?
---@param content string?
local function on_response(req, err, content)
  if req.cancelled or requests[key_of(req.buf, req.mark)] ~= req then
    return
  end

  if not vim.api.nvim_buf_is_valid(req.buf) or not vim.api.nvim_buf_is_loaded(req.buf) then
    release(req)
    return M.notify("buffer closed before the docs arrived", vim.log.levels.INFO)
  end

  local row = placeholder_row(req)
  if not row then
    release(req)
    if content then
      vim.fn.setreg('"', content)
      return M.notify("placeholder was edited; result copied to the unnamed register", vim.log.levels.WARN)
    end
    return M.notify("placeholder was edited; " .. (err or "request failed"), vim.log.levels.WARN)
  end

  if err then
    replace_placeholder(req, row, req.old_lines)
    release(req)
    return M.notify(err, vim.log.levels.ERROR)
  end

  local lines, perr = format.postprocess(req.spec, content, req.indent, M.config, req.ctx)
  if not lines then
    replace_placeholder(req, row, req.old_lines)
    release(req)
    vim.fn.setreg('"', content)
    return M.notify(perr .. " (raw output copied to the unnamed register)", vim.log.levels.ERROR)
  end

  replace_placeholder(req, row, lines)
  release(req)
  M.notify("generated docs" .. (req.name and (" for " .. req.name) or ""), vim.log.levels.INFO)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---@param opts? { bufnr?: integer, levels?: integer }
function M.generate(opts)
  opts = opts or {}
  local buf = opts.bufnr or vim.api.nvim_get_current_buf()
  local levels = opts.levels or 0

  if not vim.bo[buf].modifiable then
    return M.notify("buffer is not modifiable", vim.log.levels.WARN)
  end
  if vim.fn.executable("curl") == 0 then
    return M.notify("curl is not installed", vim.log.levels.ERROR)
  end
  if not openrouter.api_key() then
    return M.notify("OPENROUTER_API_KEY is not set (export it in your shell, then restart Neovim)", vim.log.levels.ERROR)
  end

  local model = M.get_model()
  if not model then
    M.notify("no model selected yet, opening the picker (:DocModel)", vim.log.levels.WARN)
    return M.select_model({
      on_done = function()
        M.generate(opts)
      end,
    })
  end

  local spec, serr = languages.get(buf, M.config)
  if not spec then
    return M.notify(serr, vim.log.levels.WARN)
  end

  local target, terr = ts.find_target(buf, spec, levels)
  if not target then
    return M.notify(terr or "no function under cursor", vim.log.levels.WARN)
  end

  -- Re-triggering on a function that is already in flight acts as a retry.
  local running = request_at(buf, target.insert_row)
  if running then
    cancel_request(running, true)
    target, terr = ts.find_target(buf, spec, levels)
    if not target then
      return M.notify(terr or "no function under cursor", vim.log.levels.WARN)
    end
  end

  local ctx = ts.collect_context(buf, target, spec, M.config)
  local system, user = format.build_prompt(spec, ctx, M.config)

  local s_row, e_row, old_lines = target.insert_row, target.insert_row, {}
  if target.doc_range then
    s_row, e_row = target.doc_range.start_row, target.doc_range.end_row
    old_lines = vim.api.nvim_buf_get_lines(buf, s_row, e_row, false)
  end
  local placeholder = vim.tbl_map(function(l)
    return target.indent .. l
  end, spec.placeholder(M.config.placeholder_text))

  vim.api.nvim_buf_set_lines(buf, s_row, e_row, false, placeholder)
  local mark = vim.api.nvim_buf_set_extmark(buf, ns, s_row, 0, {
    right_gravity = false,
    virt_text = { { " " .. model, "Comment" } },
    virt_text_pos = "eol",
  })

  ---@type docgen.Request
  local req = {
    buf = buf,
    mark = mark,
    old_lines = old_lines,
    placeholder = placeholder,
    indent = target.indent,
    spec = spec,
    ctx = ctx,
    name = target.name,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    cancelled = false,
  }
  requests[key_of(buf, mark)] = req

  req.proc = openrouter.chat({
    model = model,
    system = system,
    user = user,
    max_tokens = M.config.max_tokens,
    temperature = M.config.temperature,
    timeout_ms = M.config.timeout_ms,
    site_url = M.config.site_url,
    app_name = M.config.app_name,
  }, function(err, content)
    on_response(req, err, content)
  end)
end

---@param m docgen.Model
---@return string
local function format_model(m)
  return ("%-44s %5dk  $%.2f / $%.2f per M   %s"):format(
    m.id,
    math.floor(m.context_length / 1000),
    m.prompt_price * 1e6,
    m.completion_price * 1e6,
    m.name
  )
end

---@param opts? { refresh?: boolean, on_done?: fun(model: docgen.Model) }
function M.select_model(opts)
  opts = opts or {}
  if not openrouter.api_key() then
    return M.notify("OPENROUTER_API_KEY is not set (export it in your shell, then restart Neovim)", vim.log.levels.ERROR)
  end
  if opts.refresh then
    M.notify("fetching models from OpenRouter...", vim.log.levels.INFO)
  end
  openrouter.list_models({
    refresh = opts.refresh,
    ttl_s = M.config.models_cache_ttl_s,
    timeout_ms = M.config.timeout_ms,
  }, function(err, models)
    if err then
      return M.notify("failed to fetch models: " .. err, vim.log.levels.ERROR)
    end
    local current = M.get_model()
    vim.ui.select(models, {
      prompt = "OpenRouter model" .. (current and (" (current: " .. current .. ")") or ""),
      format_item = format_model,
    }, function(choice)
      if not choice then
        return
      end
      openrouter.save_model(choice)
      M.notify("model set to " .. choice.id, vim.log.levels.INFO)
      if opts.on_done then
        opts.on_done(choice)
      end
    end)
  end)
end

return M
