local Event = require("optpack.core.event").Event

local Updater = {}

--- @async
--- @param emitter OptpackEventEmitter
function Updater.start(emitter, directory, version)
  local git = require("optpack.lib.git")

  local before_revision = git.get_revision(directory, "HEAD")
  git.fetch(directory)
  git.update(directory, version)
  local revision = git.get_revision(directory, "HEAD")
  if before_revision == revision then
    return false
  end

  local revision_range = before_revision .. "..." .. revision
  local outputs = git.log(directory, revision_range)

  emitter:emit(Event.Updated, revision_range) -- to output in sync with GitCommitLog
  if not outputs then
    return false
  end
  emitter:emit(Event.GitCommitLog, outputs)
  return true
end

return Updater
