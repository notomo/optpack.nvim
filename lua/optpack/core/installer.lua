local Event = require("optpack.core.event").Event
local Promise = require("optpack.lib.promise").Promise

local M = {}

local Installer = {}
Installer.__index = Installer
M.Installer = Installer

function Installer.new(git, directory, url, depth)
  vim.validate({
    git = {git, "table"},
    directory = {directory, "string"},
    url = {url, "string"},
    depth = {depth, "number"},
  })
  local tbl = {_git = git, _directory = directory, _url = url, _depth = depth}
  return setmetatable(tbl, Installer)
end

function Installer.already(self)
  return vim.fn.isdirectory(self._directory) ~= 0
end

function Installer.start(self, emitters)
  if self:already() then
    return Promise.resolve(false)
  end

  return self._git:clone(self._directory, self._url, self._depth):next(function(output)
    emitters:emit(Event.GitCloned, output)
    emitters:emit(Event.Installed)
    return true
  end)
end

return M
