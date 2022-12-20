local M = {}

local Job = {}
Job.__index = Job

function Job.new(id)
  local tbl = { _id = id }
  return setmetatable(tbl, Job)
end

function Job.is_running(self)
  return vim.fn.jobwait({ self._id }, 0)[1] == -1
end

function Job.stop(self)
  vim.fn.jobstop(self._id)
end

function Job.close_stdin(self)
  vim.fn.chanclose(self._id, "stdin")
end

function Job.input(self, text)
  if not self:is_running() then
    return "job is not running"
  end

  local ok, err = pcall(vim.fn.chansend, self._id, text)
  if not ok then
    return err
  end
  return nil
end

function M.start(cmd, opts)
  opts = opts or vim.empty_dict()
  local ok, id_or_err = pcall(vim.fn.jobstart, cmd, opts)
  if not ok then
    return nil, id_or_err
  end
  return Job.new(id_or_err)
end

function M.open_terminal(cmd, opts)
  opts = opts or vim.empty_dict()
  local ok, id_or_err = pcall(vim.fn.termopen, cmd, opts)
  if not ok then
    return nil, id_or_err
  end
  return Job.new(id_or_err)
end

return M
