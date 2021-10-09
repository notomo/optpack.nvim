local vim = vim

local M = {}

local ParallelLimitter = {}
ParallelLimitter.__index = ParallelLimitter
M.ParallelLimitter = ParallelLimitter

function ParallelLimitter.new(limit, interval)
  vim.validate({limit = {limit, "number"}})
  if limit <= 0 then
    error("limit: must be natural number")
  end
  local tbl = {_limit = limit, _queued = {}, _running = {}, _interval = interval or 500}
  return setmetatable(tbl, ParallelLimitter)
end

function ParallelLimitter.add(self, f)
  table.insert(self._queued, f)
end

function ParallelLimitter.start(self, on_finished, next_time_ms)
  vim.validate({
    on_finished = {on_finished, "function"},
    next_time_ms = {next_time_ms, "number", true},
  })
  next_time_ms = next_time_ms or 0

  vim.loop.new_timer():start(next_time_ms, 0, vim.schedule_wrap(function()
    self:_remove_finished()
    self:_consume_queued(self._limit - #self._running)
    if #self._queued == 0 and #self._running == 0 then
      on_finished()
    else
      self:start(on_finished, self._interval)
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
    local is_running = f()
    if type(is_running) == "function" then
      table.insert(self._running, is_running)
    end
  end
end

return M
