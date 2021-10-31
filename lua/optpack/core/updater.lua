local Event = require("optpack.core.event").Event

local M = {}

local Updater = {}
Updater.__index = Updater
M.Updater = Updater

function Updater.new(git, installer, directory)
  vim.validate({
    git = {git, "table"},
    installer = {installer, "table"},
    directory = {directory, "string"},
  })
  local tbl = {_git = git, _installer = installer, _directory = directory}
  return setmetatable(tbl, Updater)
end

function Updater.start(self, emitters)
  if not self._installer:already() then
    return self._installer:start(emitters)
  end

  local before_revision, pull_output
  return self._git:get_revision(self._directory):next(function(revision)
    before_revision = revision
    return self._git:pull(self._directory)
  end):next(function(output)
    pull_output = output
    return self._git:get_revision(self._directory)
  end):next(function(revision)
    if before_revision == revision then
      return
    end
    emitters:emit(Event.GitPulled, pull_output)
    local revision_diff = before_revision .. "..." .. revision
    emitters:emit(Event.Updated, revision_diff)
    return self._git:log(self._directory, revision_diff)
  end):next(function(output)
    if not output then
      return
    end
    emitters:emit(Event.GitCommitLog, output)
  end)
end

return M
