local M = {}

local OrderedDict = {}
OrderedDict.__index = OrderedDict
M.OrderedDict = OrderedDict

function OrderedDict.new()
  local tbl = {_data = {}, _indexes = {}, _index = 0}
  return setmetatable(tbl, OrderedDict)
end

function OrderedDict.raw(self)
  local items = {}
  for k, v in self:iter() do
    table.insert(items, {key = k, value = v})
  end
  return items
end

function OrderedDict.iter(self)
  local items = {}
  for k, v in pairs(self._data) do
    table.insert(items, {value = v, key = k, index = self._indexes[k]})
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

function OrderedDict.get(self, k)
  return self._data[k]
end

function OrderedDict.has(self, k)
  return self:get(k) ~= nil
end

function OrderedDict.__newindex(self, k, v)
  self._index = self._index + 1
  self._data[k] = v
  self._indexes[k] = self._index
end

return M
