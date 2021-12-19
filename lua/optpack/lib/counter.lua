local M = {}

local Counter = {}
Counter.__index = Counter
M.Counter = Counter

function Counter.new(all_count, handler, initial_count)
  vim.validate({
    all_count = {all_count, "number"},
    handler = {handler, "function"},
    initial_count = {initial_count, "number", true},
  })
  local tbl = {_all_count = all_count, _handler = handler, _initial_count = initial_count or 0}
  tbl._handler(tbl._initial_count, tbl._all_count)
  return setmetatable(tbl, Counter)
end

function Counter.increment(self)
  return Counter.new(self._all_count, self._handler, self._initial_count + 1)
end

return M
