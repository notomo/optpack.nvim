local Promise = require("optpack.vendor.promise")
local vim = vim

local M = {}

local ParallelLimitter = {}
ParallelLimitter.__index = ParallelLimitter
M.ParallelLimitter = ParallelLimitter

function ParallelLimitter.new(limit)
  vim.validate({ limit = { limit, "number" } })
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
  return Promise.new(function(resolve, reject)
    self:_start(resolve, reject, self._limit)
  end)
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

return M
