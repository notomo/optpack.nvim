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
    if before_revision ~= revision then
      emitters:emit(Event.GitPulled, pull_output)
      emitters:emit(Event.Updated)
    end
  end):catch(function(err)
    emitters:emit(Event.Error, err)
  end)
end

return M
