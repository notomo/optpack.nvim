local Installer = {}

function Installer.already(directory)
  return vim.fn.isdirectory(directory) ~= 0
end

--- @param emitter OptpackEventEmitter
function Installer.start(emitter, directory, url, depth, version)
  local git = require("optpack.lib.git")

  if Installer.already(directory) then
    return require("optpack.vendor.promise").resolve(false)
  end

  return git
    .clone(directory, url, depth)
    :next(function()
      return git.update(directory, version)
    end)
    :next(function()
      emitter:emit(require("optpack.core.event").Event.Installed)
      return true
    end)
end

return Installer
