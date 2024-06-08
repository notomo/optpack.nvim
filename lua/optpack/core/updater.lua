local Event = require("optpack.core.event").Event

local Updater = {}

--- @param emitter OptpackEventEmitter
function Updater.start(emitter, directory)
  local git = require("optpack.lib.git")

  local before_revision
  local revision_range
  return git
    .get_revision(directory)
    :next(function(revision)
      before_revision = revision
      return git.pull(directory)
    end)
    :next(function()
      return git.get_revision(directory)
    end)
    :next(function(revision)
      if before_revision == revision then
        return
      end
      revision_range = before_revision .. "..." .. revision
      return git.log(directory, revision_range)
    end)
    :next(function(outputs)
      if revision_range then
        emitter:emit(Event.Updated, revision_range) -- to output in sync with GitCommitLog
      end
      if not outputs then
        return false
      end
      emitter:emit(Event.GitCommitLog, outputs)
      return true
    end)
end

return Updater
