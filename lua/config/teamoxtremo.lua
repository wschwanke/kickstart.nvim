local M = {}

M.util = setmetatable({}, {
  __index = function(t, k)
    local mod = require("utils." .. k)
    rawset(t, k, mod)
    return mod
  end,
})

_G.TeamoXtremo = M

return M
