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

function Updater.start(self, outputters)
  if not self._installer:already() then
    return self._installer:start(outputters)
  end

  local before_revision, pull_lines
  return self._git:get_revision(self._directory):next(function(revision)
    before_revision = revision
    return self._git:pull(self._directory)
  end):next(function(lines)
    pull_lines = lines
    return self._git:get_revision(self._directory)
  end):next(function(revision)
    if before_revision ~= revision then
      outputters:with({speaker = "git"}):info("pull", pull_lines)
      outputters:info("updated")
    end
  end):catch(function(lines)
    outputters:error("error", lines)
  end)
end

return M
