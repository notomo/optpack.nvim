local M = {}

local Git = {}
Git.__index = Git
M.Git = Git

function Git.new(job_factory)
  vim.validate({job_factory = {job_factory, "table"}})
  local tbl = {_job_factory = job_factory}
  return setmetatable(tbl, Git)
end

-- TODO: refactor

function Git.clone(self, outputters, directory, url, depth)
  local cmd = {"git", "clone"}
  if depth > 0 then
    vim.list_extend(cmd, {"--depth", depth})
  end
  vim.list_extend(cmd, {"--", url .. ".git", directory})

  outputters = outputters:with({event_name = "clone"})
  local job, err = self._job_factory:create(cmd, {
    on_exit = function(_, code)
      outputters = outputters:with({event_name = "cloned"})
      if code ~= 0 then
        outputters:error("ng")
      end
    end,
    on_stdout = function(_, data, _)
      data = vim.tbl_filter(function(v)
        return v ~= ""
      end, data)
      for _, msg in ipairs(data) do
        outputters:info(msg)
      end
    end,
    on_stderr = function(_, data, _)
      data = vim.tbl_filter(function(v)
        return v ~= ""
      end, data)
      for _, msg in ipairs(data) do
        outputters:error(msg)
      end
    end,
    stderr_buffered = true,
    stdout_buffered = true,
  })
  if err then
    return outputters:error(err)
  end

  return function()
    return job:is_running()
  end
end

function Git.pull(self, outputters, directory)
  local cmd = {"git", "pull", "--ff-only", "--rebase=false"}

  outputters = outputters:with({event_name = "clone"})
  local job, err = self._job_factory:create(cmd, {
    on_exit = function(_, code)
      outputters = outputters:with({event_name = "cloned"})
      if code ~= 0 then
        outputters:error("ng")
      end
    end,
    on_stdout = function(_, data, _)
      data = vim.tbl_filter(function(v)
        return v ~= ""
      end, data)
      for _, msg in ipairs(data) do
        outputters:info(msg)
      end
    end,
    on_stderr = function(_, data, _)
      data = vim.tbl_filter(function(v)
        return v ~= ""
      end, data)
      for _, msg in ipairs(data) do
        outputters:error(msg)
      end
    end,
    stderr_buffered = true,
    stdout_buffered = true,
    cwd = directory,
  })
  if err then
    return outputters:error(err)
  end

  return function()
    return job:is_running()
  end
end

return M
