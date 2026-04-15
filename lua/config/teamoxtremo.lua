local M = {}

M.util = setmetatable({}, {
  __index = function(t, k)
    local mod = require("utils." .. k)
    rawset(t, k, mod)
    return mod
  end,
})

for k, v in pairs(require("config.settings")) do
  M[k] = v
end

_G.TeamoXtremo = M

return M
