local Installer = {}

function Installer.already(directory)
  return vim.fn.isdirectory(directory) ~= 0
end

--- @async
--- @param emitter OptpackEventEmitter
function Installer.start(emitter, directory, url, depth, version)
  local git = require("optpack.lib.git")

  if Installer.already(directory) then
    return false
  end

  git.clone(directory, url, depth)
  git.update(directory, version)
  emitter:emit(require("optpack.core.event").Event.Installed)
  return true
end

return Installer
