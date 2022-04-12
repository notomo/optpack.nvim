local Job = {}
Job.__index = Job

function Job.new(id)
  vim.validate({ id = { id, "number" } })
  local tbl = { id = id }
  return setmetatable(tbl, Job)
end

function Job.is_running(self)
  return vim.fn.jobwait({ self.id }, 0)[1] == -1
end

local JobFactory = {}
JobFactory.__index = JobFactory

function JobFactory.new()
  local tbl = {}
  return setmetatable(tbl, JobFactory)
end

function JobFactory.create(_, cmd, opts)
  local ok, id_or_err = pcall(vim.fn.jobstart, cmd, opts)
  if not ok then
    return nil, id_or_err
  end
  return Job.new(id_or_err)
end

return JobFactory
