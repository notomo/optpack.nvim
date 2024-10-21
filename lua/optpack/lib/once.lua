local Once = {}
Once.__index = Once

--- @param f function
function Once.new(f)
  local tbl = { _called = false, _f = f }
  return setmetatable(tbl, Once)
end

function Once.__call(self, ...)
  if self._called then
    return
  end
  self._called = true
  self._f(...)
end

return Once
