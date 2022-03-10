local Event = require("optpack.core.event").Event
local JobFactory = require("optpack.lib.job_factory").JobFactory
local Git = require("optpack.lib.git").Git

local Updater = {}
Updater.__index = Updater

function Updater.new()
  local tbl = { _git = Git.new(JobFactory.new()) }
  return setmetatable(tbl, Updater)
end

function Updater.start(self, emitter, directory)
  local before_revision
  return self._git
    :get_revision(directory)
    :next(function(revision)
      before_revision = revision
      return self._git:pull(directory)
    end)
    :next(function()
      return self._git:get_revision(directory)
    end)
    :next(function(revision)
      if before_revision == revision then
        return
      end
      local revision_range = before_revision .. "..." .. revision
      emitter:emit(Event.Updated, revision_range)
      return self._git:log(directory, revision_range)
    end)
    :next(function(output)
      if not output then
        return false
      end
      emitter:emit(Event.GitCommitLog, output)
      return true
    end)
end

return Updater
