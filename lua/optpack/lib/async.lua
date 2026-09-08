local M = {}

--- @async
--- @param fs (async fun(): any)[] run concurrently
--- @return any[] # the values in the given order, raising the first error
function M.all(fs)
  local tasks = vim
    .iter(fs)
    :map(function(f)
      -- WHY: a child task that fails closes its siblings, while Promise.all
      -- left the other promises running
      -- NOT: vim.async.run(f) without detaching it
      return vim.async.run(f):detach()
    end)
    :totable()

  local values = {}
  for i, task in ipairs(tasks) do
    values[i] = vim.async.await(task)
  end
  return values
end

return M
