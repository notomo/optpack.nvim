local GitClient = require("optpack.lib.testlib.git_client").GitClient
local pathlib = require("optpack.lib.path")
local logger = require("optpack.lib.testlib.logger"):add_prefix("[git_server]")

local M = {}

local GitServer = {}
GitServer.__index = GitServer
M.GitServer = GitServer

function GitServer.new(cgi_root_dir, git_root_dir, tmp_dir)
  local port = 8888
  local job_id = vim.fn.jobstart({"python", "-m", "http.server", port, "--cgi"}, {
    on_stdout = function(_, data)
      local msg = table.concat(data, "")
      if msg ~= "" then
        logger:info(msg)
      end
    end,
    on_stderr = function(_, data)
      local msg = table.concat(data, "")
      if msg ~= "" then
        logger:warn(msg)
      end
    end,
    env = {GIT_PROJECT_ROOT = git_root_dir, GIT_HTTP_EXPORT_ALL = "true"},
    cwd = cgi_root_dir,
  })

  vim.fn.mkdir(git_root_dir, "p")
  vim.fn.mkdir(tmp_dir, "p")

  local cgi_url = ("http://127.0.0.1:%d/cgi-bin"):format(port)
  local url = pathlib.join(cgi_url, "git-http-backend")
  local client = GitClient.new(url)
  local tbl = {
    url = url,
    client = client,
    _cgi_url = cgi_url,
    _job_id = job_id,
    _tmp_dir = tmp_dir,
    _git_root_dir = git_root_dir,
  }
  local self = setmetatable(tbl, GitServer)
  self:_health_check()
  return self
end

function GitServer.create_repository(self, full_name, commits)
  local tmp_path = pathlib.join(self._tmp_dir, full_name)
  vim.fn.mkdir(tmp_path, "p")

  self.client:execute({"init"}, {cwd = tmp_path})

  self:_add_commit(tmp_path, "init")
  for _, msg in ipairs(commits or {}) do
    self:_add_commit(tmp_path, msg)
  end

  local account_name = vim.split(full_name, "/", true)[1]
  local path = pathlib.join(self._git_root_dir, account_name)
  vim.fn.mkdir(path, "p")
  self.client:execute({"clone", "--bare", "--local", tmp_path}, {cwd = path})
end

function GitServer._add_commit(self, tmp_path, msg)
  local name = ("%s_file"):format(msg)
  local file = pathlib.join(tmp_path, name)
  io.open(file, "w"):close()
  self.client:execute({"add", "."}, {cwd = tmp_path})
  self.client:execute({"commit", "-m", msg}, {cwd = tmp_path})
end

function GitServer.teardown(self)
  vim.fn.jobstop(self._job_id)
  vim.fn.delete(self._tmp_dir, "rf")
  vim.fn.delete(self._git_root_dir, "rf")
end

function GitServer._health_check(self)
  local ok = vim.wait(1000, function()
    local exit_code
    local job_id = vim.fn.jobstart({"curl", pathlib.join(self._cgi_url, "ready.py")}, {
      on_exit = function(_, code)
        exit_code = code
      end,
    })
    vim.fn.jobwait({job_id}, 1000)
    return exit_code == 0
  end, 100)
  if not ok then
    error("cgi server is not health.")
  end
end

return M
