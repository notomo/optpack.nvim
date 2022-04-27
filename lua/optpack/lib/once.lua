local Once = {}
Once.__index = Once

function Once.new(f)
  vim.validate({ f = { f, "function" } })
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
