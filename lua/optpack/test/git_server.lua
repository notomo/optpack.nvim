local GitClient = require("optpack.test.git_client")
local log = require("optpack.test.logger")
local logger = log.logger:add_prefix("[git_server]")

local GitServer = {}
GitServer.__index = GitServer

function GitServer.new(cgi_root_dir, git_root_dir, tmp_dir)
  local port = 8888
  local job = vim.system({ "python", "-m", "http.server", tostring(port), "--cgi" }, {
    cwd = cgi_root_dir,
    env = {
      GIT_PROJECT_ROOT = git_root_dir,
      GIT_HTTP_EXPORT_ALL = "true",
    },
    text = true,
    stdout = function(_, data)
      if not data then
        return
      end
      logger:info(data)
    end,
    stderr = function(_, data)
      if not data then
        return
      end
      logger:warn(data)
    end,
  })

  vim.fn.mkdir(git_root_dir, "p")
  vim.fn.mkdir(tmp_dir, "p")

  local cgi_url = ("http://127.0.0.1:%d/cgi-bin"):format(port)
  local url = cgi_url .. "/git-http-backend"
  local client = GitClient.new(url)
  local tbl = {
    url = url,
    client = client,
    _cgi_url = cgi_url,
    _job = job,
    _tmp_dir = tmp_dir,
    _git_root_dir = git_root_dir,
  }
  local self = setmetatable(tbl, GitServer)
  self:_health_check()
  return self
end

function GitServer.create_repository(self, full_name, raw_opts)
  local opts = vim.tbl_extend("force", {
    commits = {
      main = {},
    },
  }, raw_opts or {})

  local tmp_path = vim.fs.joinpath(self._tmp_dir, full_name)
  vim.fn.mkdir(tmp_path, "p")

  self.client:execute({ "init" }, { cwd = tmp_path })
  self.client:execute({ "config", "--local", "user.email", "notomo@example.com" }, { cwd = tmp_path })
  self.client:execute({ "config", "--local", "user.name", "notomo" }, { cwd = tmp_path })
  self.client:execute({ "config", "--local", "init.defaultBranch", "main" }, { cwd = tmp_path })

  local account_name = vim.split(full_name, "/", { plain = true })[1]
  local path = vim.fs.joinpath(self._git_root_dir, account_name)
  vim.fn.mkdir(path, "p")

  self:_add_commit(tmp_path, "init")
  for branch_name, commits in pairs(opts.commits) do
    for _, msg in ipairs(commits or {}) do
      self:_add_branch(tmp_path, branch_name)
      self:_add_commit(tmp_path, msg)
    end
  end
  self.client:execute({ "switch", "main" }, { cwd = tmp_path })

  self.client:execute({ "clone", "--bare", "--local", tmp_path }, { cwd = path })
end

function GitServer._add_commit(self, tmp_path, msg)
  local name = ("%s_file"):format(msg)
  local file = vim.fs.joinpath(tmp_path, name)
  io.open(file, "w"):close()
  self.client:execute({ "add", "." }, { cwd = tmp_path })
  self.client:execute({ "commit", "-m", msg }, { cwd = tmp_path })
end

function GitServer._add_branch(self, tmp_path, name)
  self.client:execute({ "switch", "-C", name }, { cwd = tmp_path })
end

function GitServer.teardown(self)
  vim.fn.delete(self._tmp_dir, "rf")
  vim.fn.delete(self._git_root_dir, "rf")
  self._job:kill()
end

function GitServer._health_check(self)
  local ok = vim.wait(1000, function()
    local job = vim.system({ "curl", self._cgi_url .. "/ready.py" }):wait(1000)
    return job.code == 0
  end, 100)
  if not ok then
    error("cgi server is not health.")
  end
end

return GitServer
