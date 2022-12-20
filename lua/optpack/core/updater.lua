local Event = require("optpack.core.event").Event

local Updater = {}
Updater.__index = Updater

function Updater.new()
  local git = require("optpack.lib.git").new()
  local tbl = { _git = git }
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
    :next(function(outputs)
      if not outputs then
        return false
      end
      emitter:emit(Event.GitCommitLog, outputs)
      return true
    end)
end

return Updater
