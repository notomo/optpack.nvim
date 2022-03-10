local Event = require("optpack.core.event").Event
local Promise = require("optpack.lib.promise")
local JobFactory = require("optpack.lib.job_factory").JobFactory
local Git = require("optpack.lib.git").Git

local Installer = {}
Installer.__index = Installer

function Installer.new()
  local tbl = { _git = Git.new(JobFactory.new()) }
  return setmetatable(tbl, Installer)
end

function Installer.already(directory)
  return vim.fn.isdirectory(directory) ~= 0
end

function Installer.start(self, emitter, directory, url, depth)
  if Installer.already(directory) then
    return Promise.resolve(false)
  end

  return self._git:clone(directory, url, depth):next(function()
    emitter:emit(Event.Installed)
    return true
  end)
end

return Installer
