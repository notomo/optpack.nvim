local ParallelLimitter = {}
ParallelLimitter.__index = ParallelLimitter

--- @param limit integer
function ParallelLimitter.new(limit)
  if limit <= 0 then
    error("limit: must be natural number")
  end
  local tbl = { _limit = limit, _queued = {} }
  return setmetatable(tbl, ParallelLimitter)
end

--- @param f async fun()
function ParallelLimitter.add(self, f)
  table.insert(self._queued, f)
end

--- @async
--- @return nil
function ParallelLimitter.start(self)
  local semaphore = vim.async.semaphore(self._limit)
  local tasks = vim
    .iter(self._queued)
    :map(function(f)
      --- @async
      --- @return nil
      local run = function()
        semaphore:with(f)
      end
      -- WHY: the failure of an attached child fails this task too, so the first
      -- one would close the rest instead of letting them settle
      -- NOT: vim.async.run(run) without detaching it
      return vim.async.run(run):detach()
    end)
    :totable()
  self._queued = {}

  for _, task in ipairs(tasks) do
    vim.async.pawait(task)
  end
end

return ParallelLimitter
