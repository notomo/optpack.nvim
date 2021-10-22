local Output = require("optpack.lib.output").Output

local M = {}

local GitServer = {}
GitServer.__index = GitServer
M.GitServer = GitServer

function GitServer.new(cgi_root_dir, git_root_dir, tmp_dir)
  local job_id = vim.fn.jobstart({"python", "-m", "http.server", "--cgi"}, {
    on_stdout = function(_, data)
      -- TODO log
    end,
    on_stderr = function(_, data)
      -- TODO log
    end,
    env = {GIT_PROJECT_ROOT = git_root_dir},
    cwd = cgi_root_dir,
  })
  -- TODO wait to ready
  vim.wait(30, function()
    return false
  end)
  vim.fn.mkdir(git_root_dir, "p")
  local tbl = {
    url = "http://127.0.0.1:8000/cgi-bin/git-http-backend/git/",
    _job_id = job_id,
    _tmp_dir = tmp_dir,
    _git_root_dir = git_root_dir,
  }
  return setmetatable(tbl, GitServer)
end

function GitServer.create_repository(self, full_name)
  local tmp_path = self._tmp_dir .. full_name
  vim.fn.mkdir(tmp_path, "p")

  self:_git({"init"}, {cwd = tmp_path})

  local readme = tmp_path .. "/README.md"
  io.open(readme, "w"):close()
  self:_git({"add", "."}, {cwd = tmp_path})
  self:_git({"commit", "-m", "Init"}, {cwd = tmp_path})

  self:_git({"clone", "--bare", "--local", tmp_path})
end

function GitServer.teardown(self)
  vim.fn.jobstop(self._job_id)
end

function GitServer._git(self, cmd, opts)
  opts = opts or {}

  local stdout = Output.new()
  local stderr = Output.new()
  local job_id = vim.fn.jobstart({"git", unpack(cmd)}, {
    cwd = opts.cwd or self._git_root_dir,
    on_stdout = stdout:collector(),
    on_stderr = stderr:collector(),
  })

  local result = vim.fn.jobwait({job_id}, 1000)[1]
  if result == 0 then
    -- TODO: log
    return
  elseif result == -1 then
    error("timeout: " .. vim.inspect(cmd))
  elseif result == -3 then
    error("invalid job-id: " .. job_id)
  end

  local msg = table.concat(stderr:lines(), "")
  error(msg)
end

return M
