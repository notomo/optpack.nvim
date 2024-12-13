local logger = require("optpack.test.logger").logger:add_prefix("[git_client]")

local GitClient = {}
GitClient.__index = GitClient

function GitClient.new(server_url)
  local tbl = { _server_url = server_url }
  return setmetatable(tbl, GitClient)
end

function GitClient.clone(self, full_name, directory, args)
  local url = self._server_url .. "/" .. full_name .. ".git"
  local cmd = { "clone", unpack(args or {}) }
  vim.list_extend(cmd, { url, directory })
  self:execute(cmd)
end

function GitClient.reset_hard(self, revision, directory)
  self:execute({ "reset", "--hard", revision }, { cwd = directory })
end

function GitClient.execute(_, args, opts)
  opts = opts or {}

  local cmd = { "git", unpack(args) }
  local job = vim
    .system(cmd, {
      text = true,
      cwd = opts.cwd,
    })
    :wait()

  if job.code == 0 then
    logger:add_prefix("[cmd]"):info(table.concat(cmd, " "))

    if job.stdout ~= "" then
      logger:info(job.stdout)
    end

    if job.stderr ~= "" then
      logger:warn(job.stderr)
    end

    return
  end

  error(job.stderr)
end

return GitClient
