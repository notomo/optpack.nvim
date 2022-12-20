local Installer = {}
Installer.__index = Installer

function Installer.new()
  local git = require("optpack.lib.git").new()
  local tbl = { _git = git }
  return setmetatable(tbl, Installer)
end

function Installer.already(directory)
  return vim.fn.isdirectory(directory) ~= 0
end

function Installer.start(self, emitter, directory, url, depth)
  if Installer.already(directory) then
    return require("optpack.vendor.promise").resolve(false)
  end

  return self._git:clone(directory, url, depth):next(function()
    emitter:emit(require("optpack.core.event").Event.Installed)
    return true
  end)
end

return Installer
