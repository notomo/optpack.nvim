local M = {}
M.__index = M

function M.new()
  local tbl = { _data = {}, _indexes = {}, _index = 0 }
  return setmetatable(tbl, M)
end

function M.raw(self)
  local items = {}
  for k, v in self:iter() do
    table.insert(items, { key = k, value = v })
  end
  return items
end

function M.iter(self)
  local items = {}
  for k, v in pairs(self._data) do
    table.insert(items, { value = v, key = k, index = self._indexes[k] })
  end
  table.sort(items, function(a, b)
    return a.index < b.index
  end)

  local i = 1
  return function()
    while true do
      local item = items[i]
      if not item then
        return
      end
      i = i + 1
      return item.key, item.value
    end
  end
end

function M.merge(self, tbl)
  local new_dict = M.new()
  for k, v in self:iter() do
    new_dict[k] = v
  end
  for k, v in pairs(tbl) do
    new_dict[k] = v
  end
  return new_dict
end

function M.has(self, k)
  return self._data[k] ~= nil
end

function M.values(self)
  local values = {}
  for _, v in self:iter() do
    table.insert(values, v)
  end
  return values
end

function M.keys(self)
  local keys = {}
  for k in self:iter() do
    table.insert(keys, k)
  end
  return keys
end

function M.__index(self, k)
  local method = M[k]
  if method then
    return method
  end
  return rawget(self._data, k)
end

function M.__newindex(self, k, v)
  if not self._indexes[k] then
    self._index = self._index + 1
    self._indexes[k] = self._index
  end
  self._data[k] = v
end

return M
