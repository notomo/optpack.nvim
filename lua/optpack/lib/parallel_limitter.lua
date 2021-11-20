local Promise = require("optpack.lib.promise").Promise
local vim = vim

local M = {}

local ParallelLimitter = {}
ParallelLimitter.__index = ParallelLimitter
M.ParallelLimitter = ParallelLimitter

function ParallelLimitter.new(limit)
  vim.validate({limit = {limit, "number"}})
  if limit <= 0 then
    error("limit: must be natural number")
  end
  local tbl = {_limit = limit, _queued = {}, _started = {}}
  return setmetatable(tbl, ParallelLimitter)
end

function ParallelLimitter.add(self, f)
  table.insert(self._queued, f)
end

function ParallelLimitter.start(self)
  return Promise.new(function(resolve)
    self:_start(resolve, self._limit)
  end)
end

function ParallelLimitter._start(self, resolve, count)
  local funcs = vim.list_slice(self._queued, 0, count)
  self._queued = vim.list_slice(self._queued, count + 1)
  local started = {}
  for _, f in ipairs(funcs) do
    local promise = f():finally(function()
      return self:_start(resolve, 1)
    end)
    table.insert(started, promise)
  end
  vim.list_extend(self._started, started)
  if #self._queued == 0 then
    Promise.all(self._started):next(function()
      resolve()
    end)
  end
  return Promise.all(started)
end

return M
