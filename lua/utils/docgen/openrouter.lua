-- OpenRouter HTTP client (curl via vim.system) plus on-disk persistence for the chosen model
-- and a cached copy of the model list.
local M = {}

M.API = "https://openrouter.ai/api/v1"
M.model_file = vim.fs.joinpath(vim.fn.stdpath("data"), "docgen", "model.json")
M.cache_file = vim.fs.joinpath(vim.fn.stdpath("cache"), "docgen", "models.json")

---@return string?
function M.api_key()
  local key = vim.env.OPENROUTER_API_KEY
  if key == nil or key == "" then
    return nil
  end
  return key
end

-- ---------------------------------------------------------------------------
-- JSON file helpers
-- ---------------------------------------------------------------------------

---@return table?
local function read_json(path)
  if not vim.uv.fs_stat(path) then
    return nil
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return nil
  end
  local ok2, data = pcall(vim.json.decode, table.concat(lines, "\n"), { luanil = { object = true, array = true } })
  if not ok2 or type(data) ~= "table" then
    return nil
  end
  return data
end

local function write_json(path, data)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile({ vim.json.encode(data) }, path)
end

-- ---------------------------------------------------------------------------
-- HTTP
-- ---------------------------------------------------------------------------

---@param res vim.SystemCompleted
---@param timeout_ms integer
---@return string? err, table? data
local function parse_response(res, timeout_ms)
  -- vim.system's own timeout kills with SIGTERM and sets code 124; curl --max-time exits 28.
  if res.code == 124 or res.code == 28 then
    return ("request timed out after %ds"):format(math.ceil(timeout_ms / 1000))
  end
  if res.signal and res.signal ~= 0 then
    return "cancelled"
  end
  if res.code ~= 0 then
    local stderr = vim.trim(res.stderr or "")
    return ("curl failed (exit %d): %s"):format(res.code, stderr ~= "" and stderr or "unknown error")
  end

  -- `-w "\n%{http_code}"` appends the status on its own line after the body.
  local stdout = res.stdout or ""
  local body, status = stdout:match("^(.*)\n(%d+)%s*$")
  if not status then
    return "unexpected curl output: " .. stdout:sub(1, 200)
  end

  local ok, data = pcall(vim.json.decode, body, { luanil = { object = true, array = true } })
  if not ok or type(data) ~= "table" then
    data = nil
  end

  local code = tonumber(status) or 0
  if code < 200 or code >= 300 then
    local msg = data and vim.tbl_get(data, "error", "message")
    if type(msg) ~= "string" or msg == "" then
      msg = vim.trim(body):sub(1, 200)
    end
    return ("HTTP %d: %s"):format(code, msg)
  end
  if not data then
    return "malformed JSON response from OpenRouter"
  end
  return nil, data
end

---@class docgen.RequestOpts
---@field method "GET"|"POST"
---@field path string
---@field body? table
---@field headers? string[]
---@field timeout_ms? integer

-- NOTE: the bearer token is visible in `ps` for the duration of the request. Fine for a
-- single-user machine; switch to `-H @file` if that ever matters.
---@param opts docgen.RequestOpts
---@param cb fun(err: string?, data: table?)  -- always invoked on the main loop
---@return vim.SystemObj?
local function request(opts, cb)
  local key = M.api_key()
  if not key then
    vim.schedule(function()
      cb("OPENROUTER_API_KEY is not set (export it in your shell, then restart Neovim)")
    end)
    return nil
  end

  local timeout_ms = opts.timeout_ms or 30000
  local cmd = {
    "curl",
    "-sS",
    "-X",
    opts.method,
    M.API .. opts.path,
    "-H",
    "Authorization: Bearer " .. key,
    "-H",
    "Content-Type: application/json",
    "-H",
    "Accept: application/json",
    "--max-time",
    tostring(math.ceil(timeout_ms / 1000)),
    "-w",
    "\n%{http_code}",
  }
  for _, header in ipairs(opts.headers or {}) do
    vim.list_extend(cmd, { "-H", header })
  end

  local stdin
  if opts.body then
    -- Body goes over stdin: no shell quoting issues and no temp file.
    vim.list_extend(cmd, { "--data-binary", "@-" })
    stdin = vim.json.encode(opts.body)
  end

  return vim.system(cmd, { stdin = stdin, text = true, timeout = timeout_ms }, function(res)
    local err, data = parse_response(res, timeout_ms)
    vim.schedule(function()
      cb(err, data)
    end)
  end)
end

---@class docgen.ChatOpts
---@field model string
---@field system string
---@field user string
---@field max_tokens? integer
---@field temperature? number
---@field timeout_ms? integer
---@field site_url? string
---@field app_name? string

---@param opts docgen.ChatOpts
---@param cb fun(err: string?, content: string?)
---@return vim.SystemObj?
function M.chat(opts, cb)
  local headers = {}
  if opts.site_url then
    headers[#headers + 1] = "HTTP-Referer: " .. opts.site_url
  end
  if opts.app_name then
    headers[#headers + 1] = "X-Title: " .. opts.app_name
  end

  return request({
    method = "POST",
    path = "/chat/completions",
    timeout_ms = opts.timeout_ms,
    headers = headers,
    body = {
      model = opts.model,
      messages = {
        { role = "system", content = opts.system },
        { role = "user", content = opts.user },
      },
      max_tokens = opts.max_tokens,
      temperature = opts.temperature,
    },
  }, function(err, data)
    if err then
      return cb(err)
    end
    local content = vim.tbl_get(data, "choices", 1, "message", "content")
    if type(content) ~= "string" or content:match("^%s*$") then
      return cb("empty completion from model")
    end
    cb(nil, content)
  end)
end

-- ---------------------------------------------------------------------------
-- Models
-- ---------------------------------------------------------------------------

---@class docgen.Model
---@field id string
---@field name string
---@field context_length integer
---@field prompt_price number      -- USD per token
---@field completion_price number  -- USD per token

---@param raw table
---@return docgen.Model?
local function trim_model(raw)
  if type(raw.id) ~= "string" then
    return nil
  end
  local modalities = vim.tbl_get(raw, "architecture", "output_modalities")
  if type(modalities) == "table" and not vim.tbl_contains(modalities, "text") then
    return nil
  end
  local pricing = raw.pricing or {}
  return {
    id = raw.id,
    name = raw.name or raw.id,
    context_length = tonumber(raw.context_length) or 0,
    prompt_price = tonumber(pricing.prompt) or 0,
    completion_price = tonumber(pricing.completion) or 0,
  }
end

---@param ttl_s integer
---@return docgen.Model[]?
function M.load_cache(ttl_s)
  local data = read_json(M.cache_file)
  if not data or type(data.models) ~= "table" or #data.models == 0 then
    return nil
  end
  local age = os.time() - (tonumber(data.fetched_at) or 0)
  if age > ttl_s then
    return nil
  end
  return data.models
end

---@param models docgen.Model[]
function M.save_cache(models)
  write_json(M.cache_file, { fetched_at = os.time(), models = models })
end

---@param opts { refresh?: boolean, ttl_s?: integer, timeout_ms?: integer }
---@param cb fun(err: string?, models: docgen.Model[]?)
function M.list_models(opts, cb)
  opts = opts or {}
  if not opts.refresh then
    local cached = M.load_cache(opts.ttl_s or 86400)
    if cached then
      return cb(nil, cached)
    end
  end

  request({ method = "GET", path = "/models", timeout_ms = opts.timeout_ms }, function(err, data)
    if err then
      return cb(err)
    end
    local models = {}
    for _, raw in ipairs(data.data or {}) do
      local m = trim_model(raw)
      if m then
        models[#models + 1] = m
      end
    end
    if #models == 0 then
      return cb("OpenRouter returned no models")
    end
    table.sort(models, function(a, b)
      return a.id < b.id
    end)
    M.save_cache(models)
    cb(nil, models)
  end)
end

---@return { model: string, name?: string, chosen_at?: integer }?
function M.load_model()
  local data = read_json(M.model_file)
  if not data or type(data.model) ~= "string" or data.model == "" then
    return nil
  end
  return data
end

---@param model docgen.Model
function M.save_model(model)
  write_json(M.model_file, { model = model.id, name = model.name, chosen_at = os.time() })
end

return M
