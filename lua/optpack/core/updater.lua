local Event = require("optpack.core.event").Event

local Updater = {}

--- @param emitter OptpackEventEmitter
function Updater.start(emitter, directory, version)
  local git = require("optpack.lib.git")

  local before_revision
  local revision_range
  return git
    .get_revision(directory, "HEAD")
    :next(function(revision)
      before_revision = revision
      return git.fetch(directory)
    end)
    :next(function()
      return git.update(directory, version)
    end)
    :next(function()
      return git.get_revision(directory, "HEAD")
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
