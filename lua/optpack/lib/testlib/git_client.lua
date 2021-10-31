local Output = require("optpack.lib.output").Output
local pathlib = require("optpack.lib.path")
local logger = require("optpack.lib.testlib.logger"):add_prefix("[git_client]")

local M = {}

local GitClient = {}
GitClient.__index = GitClient
M.GitClient = GitClient

function GitClient.new(server_url)
  local tbl = {_server_url = server_url}
  return setmetatable(tbl, GitClient)
end

function GitClient.clone(self, full_name, directory, args)
  local url = pathlib.join(self._server_url, full_name .. ".git")
  local cmd = {"clone", unpack(args or {})}
  vim.list_extend(cmd, {url, directory})
  self:execute(cmd)
end

function GitClient.reset_hard(self, revision, directory)
  self:execute({"reset", "--hard", revision}, {cwd = directory})
end

function GitClient.execute(_, args, opts)
  opts = opts or {}

  local stdout = Output.new()
  local stderr = Output.new()
  local cmd = {"git", unpack(args)}
  local job_id = vim.fn.jobstart(cmd, {
    cwd = opts.cwd,
    on_stdout = stdout:collector(),
    on_stderr = stderr:collector(),
  })

  local result = vim.fn.jobwait({job_id}, 1000)[1]
  if result == 0 then
    logger:add_prefix("[cmd]"):info(table.concat(cmd, " "))

    local stdout_msg = stdout:str()
    if stdout_msg ~= "" then
      logger:info(stdout_msg)
    end

    local stderr_msg = stderr:str()
    if stderr_msg ~= "" then
      logger:warn(stderr_msg)
    end

    return
  elseif result == -1 then
    error("timeout: " .. vim.inspect(cmd))
  elseif result == -3 then
    error("invalid job-id: " .. job_id)
  end

  error(stderr:str())
end

return M
