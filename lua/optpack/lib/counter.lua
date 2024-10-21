local Counter = {}
Counter.__index = Counter

--- @param all_count integer
--- @param handler function
--- @param initial_count integer?
function Counter.new(all_count, handler, initial_count)
  local tbl = { _all_count = all_count, _handler = handler, _initial_count = initial_count or 0 }
  tbl._handler(tbl._initial_count, tbl._all_count)
  return setmetatable(tbl, Counter)
end

function Counter.increment(self)
  return Counter.new(self._all_count, self._handler, self._initial_count + 1)
end

return Counter
