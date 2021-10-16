local Promise = require("optpack.lib.promise").Promise

local vim = vim

local M = {}

local ParallelLimitter = {}
ParallelLimitter.__index = ParallelLimitter
M.ParallelLimitter = ParallelLimitter

function ParallelLimitter.new(limit, interval)
  vim.validate({limit = {limit, "number"}, interval = {interval, "number"}})
  if limit <= 0 then
    error("limit: must be natural number")
  end
  local tbl = {_limit = limit, _queued = {}, _running = {}, _interval = interval}
  return setmetatable(tbl, ParallelLimitter)
end

function ParallelLimitter.add(self, f)
  table.insert(self._queued, f)
end

function ParallelLimitter.start(self)
  return Promise.new(function(resolve)
    self:_start(resolve, 0)
  end)
end

function ParallelLimitter._start(self, resolve, next_time_ms)
  vim.loop.new_timer():start(next_time_ms, 0, vim.schedule_wrap(function()
    self:_remove_finished()
    self:_consume_queued(self._limit - #self._running)
    if #self._queued == 0 and #self._running == 0 then
      resolve()
    else
      self:_start(resolve, self._interval)
    end
  end))
end

function ParallelLimitter._remove_finished(self)
  local finished = {}
  for i, is_running in ipairs(self._running) do
    if not is_running() then
      table.insert(finished, i)
    end
  end
  for _, i in ipairs(vim.fn.reverse(finished)) do
    table.remove(self._running, i)
  end
end

function ParallelLimitter._consume_queued(self, count)
  local funcs = vim.list_slice(self._queued, 0, count)
  self._queued = vim.list_slice(self._queued, count + 1)
  for _, f in ipairs(funcs) do
    local promise = f()
    table.insert(self._running, function()
      return promise:is_pending()
    end)
  end
end

return M
