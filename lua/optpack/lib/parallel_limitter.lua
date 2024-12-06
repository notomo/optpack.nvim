local Promise = require("optpack.vendor.promise")
local vim = vim

local ParallelLimitter = {}
ParallelLimitter.__index = ParallelLimitter

--- @param limit integer
function ParallelLimitter.new(limit)
  if limit <= 0 then
    error("limit: must be natural number")
  end
  local tbl = { _limit = limit, _queued = {}, _started = {} }
  return setmetatable(tbl, ParallelLimitter)
end

function ParallelLimitter.add(self, f)
  table.insert(self._queued, f)
end

function ParallelLimitter.start(self)
  local promise, resolve, reject = Promise.with_resolvers()
  self:_start(resolve, reject, self._limit)
  return promise
end

function ParallelLimitter._start(self, resolve, reject, count)
  local funcs = vim.list_slice(self._queued, 0, count)
  self._queued = vim.list_slice(self._queued, count + 1)

  local started = {}
  for _, f in ipairs(funcs) do
    local promise = f():finally(function()
      return self:_start(resolve, reject, 1)
    end)
    table.insert(started, promise)
  end
  vim.list_extend(self._started, started)

  if #self._queued == 0 then
    return Promise.all_settled(self._started):next(resolve, reject)
  end
  return Promise.all_settled(started)
end

return ParallelLimitter
