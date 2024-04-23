local Promise = require("optpack.vendor.promise")
local Output = require("optpack.vendor.misclib.job.output")

local Git = {}
Git.__index = Git

function Git.new()
  local tbl = {}
  return setmetatable(tbl, Git)
end

function Git.clone(self, directory, url, depth)
  local cmd = { "git", "clone", "--no-single-branch" }
  if depth > 0 then
    vim.list_extend(cmd, { "--depth", depth })
  end
  vim.list_extend(cmd, { "--", url .. ".git", directory })
  return self:_start(cmd)
end

function Git.pull(self, directory)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "pull",
    "--ff-only",
    "--rebase=false",
  }
  return self:_start(cmd, { cwd = directory })
end

function Git.get_revision(self, directory)
  local cmd = { "git", "--git-dir", vim.fs.joinpath(directory, ".git"), "rev-parse", "--short", "HEAD" }
  return self:_start(cmd, {
    cwd = directory,
    handle_stdout = function(stdout)
      return stdout:str()
    end,
  })
end

function Git.log(self, directory, target_revision)
  local cmd = {
    "git",
    "--git-dir",
    vim.fs.joinpath(directory, ".git"),
    "log",
    [[--pretty=format:%h %s]],
    target_revision,
  }
  return self:_start(cmd, { cwd = directory }):next(function(outputs)
    return vim
      .iter(outputs)
      :map(function(output)
        local index = output:find(" ")
        local revision = output:sub(1, index)
        local message = output:sub(index + 1)
        return {
          revision = revision,
          message = message,
        }
      end)
      :totable()
  end)
end

function Git._start(_, cmd, opts)
  opts = opts or {}
  opts.handle_stdout = opts.handle_stdout or function(stdout)
    return stdout:lines()
  end
  local stdout = Output.new()
  local stderr = Output.new()
  return Promise.new(function(resolve, reject)
    local _, err = require("optpack.vendor.misclib.job").start(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          local err = { table.concat(cmd, " "), unpack(stderr:lines()) }
          return reject(err)
        end
        return resolve(opts.handle_stdout(stdout))
      end,
      on_stdout = stdout:collector(),
      on_stderr = stderr:collector(),
      stderr_buffered = true,
      stdout_buffered = true,
      cwd = opts.cwd,
    })
    if err then
      return reject(err)
    end
  end)
end

return Git
