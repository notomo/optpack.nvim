local Promise = require("optpack.lib.promise").Promise
local Output = require("optpack.lib.output").Output

local M = {}

local Git = {}
Git.__index = Git
M.Git = Git

function Git.new(job_factory)
  vim.validate({job_factory = {job_factory, "table"}})
  local tbl = {_job_factory = job_factory}
  return setmetatable(tbl, Git)
end

function Git.clone(self, directory, url, depth)
  local cmd = {"git", "clone"}
  if depth > 0 then
    vim.list_extend(cmd, {"--depth", depth})
  end
  vim.list_extend(cmd, {"--", url .. ".git", directory})

  local stdout = Output.new()
  local stderr = Output.new()
  return Promise.new(function(resolve, reject)
    local _, err = self._job_factory:create(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          return reject(stderr:lines())
        end
        return resolve(stdout:lines())
      end,
      on_stdout = stdout:collector(),
      on_stderr = stderr:collector(),
      stderr_buffered = true,
      stdout_buffered = true,
    })
    if err then
      return reject(err)
    end
  end)
end

function Git.pull(self, directory)
  local cmd = {"git", "pull", "--ff-only", "--rebase=false"}
  local stdout = Output.new()
  local stderr = Output.new()
  return Promise.new(function(resolve, reject)
    local _, err = self._job_factory:create(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          return reject(stderr:lines())
        end
        return resolve(stdout:lines())
      end,
      on_stdout = stdout:collector(),
      on_stderr = stderr:collector(),
      stderr_buffered = true,
      stdout_buffered = true,
      cwd = directory,
    })
    if err then
      return reject(err)
    end
  end)
end

function Git.get_revision(self, directory)
  local cmd = {"git", "rev-parse", "HEAD"}
  local stdout = Output.new()
  local stderr = Output.new()
  return Promise.new(function(resolve, reject)
    local _, err = self._job_factory:create(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          return reject(stderr:lines())
        end
        local revision = table.concat(stdout:lines(), "")
        return resolve(revision)
      end,
      on_stdout = stdout:collector(),
      on_stderr = stderr:collector(),
      stderr_buffered = true,
      stdout_buffered = true,
      cwd = directory,
    })
    if err then
      return reject(err)
    end
  end)
end

return M
