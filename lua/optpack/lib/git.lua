local M = {}

local Git = {}
Git.__index = Git
M.Git = Git

function Git.new()
  local tbl = {}
  return setmetatable(tbl, Git)
end

-- TODO: refactor

function Git.clone(_, outputters, directory, url, depth)
  local cmd = {"git", "clone"}
  if depth > 0 then
    vim.list_extend(cmd, {"--depth", depth})
  end
  vim.list_extend(cmd, {"--", url, directory})

  outputters = outputters:with({event_name = "clone"})
  local id = vim.fn.jobstart(cmd, {
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

  local is_running = function()
    return vim.fn.jobwait({id}, 0)[1] == -1
  end
  return is_running
end

function Git.pull(_, outputters, directory)
  local cmd = {"git", "pull", "--ff-only", "--rebase=false"}

  outputters = outputters:with({event_name = "clone"})
  local id = vim.fn.jobstart(cmd, {
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

  local is_running = function()
    return vim.fn.jobwait({id}, 0)[1] == -1
  end
  return is_running
end

return M
