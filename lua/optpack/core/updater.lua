local Event = require("optpack.core.event").Event

local M = {}

local Updater = {}
Updater.__index = Updater
M.Updater = Updater

function Updater.new(git, directory)
  vim.validate({git = {git, "table"}, directory = {directory, "string"}})
  local tbl = {_git = git, _directory = directory}
  return setmetatable(tbl, Updater)
end

function Updater.start(self, emitter)
  local before_revision
  return self._git:get_revision(self._directory):next(function(revision)
    before_revision = revision
    return self._git:pull(self._directory)
  end):next(function()
    return self._git:get_revision(self._directory)
  end):next(function(revision)
    if before_revision == revision then
      return
    end
    local revision_range = before_revision .. "..." .. revision
    emitter:emit(Event.Updated, revision_range)
    return self._git:log(self._directory, revision_range)
  end):next(function(output)
    if not output then
      return false
    end
    emitter:emit(Event.GitCommitLog, output)
    return true
  end)
end

return M
