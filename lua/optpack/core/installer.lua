local Event = require("optpack.core.event").Event

local M = {}

local Installer = {}
Installer.__index = Installer
M.Installer = Installer

function Installer.new(git, directory, url, depth, revision_switcher)
  vim.validate({
    git = {git, "table"},
    directory = {directory, "string"},
    url = {url, "string"},
    depth = {depth, "number"},
    revision_switcher = {revision_switcher, "table"},
  })
  local tbl = {
    _git = git,
    _directory = directory,
    _url = url,
    _depth = depth,
    _revision_switcher = revision_switcher,
  }
  return setmetatable(tbl, Installer)
end

function Installer.already(self)
  return vim.fn.isdirectory(self._directory) ~= 0
end

function Installer.start(self, emitter)
  if self:already() then
    return self._revision_switcher:start()
  end

  -- TODO: depth=0 if needs switch?
  local installed_now
  return self._git:clone(self._directory, self._url, self._depth):next(function(output)
    emitter:emit(Event.GitCloned, output)
    emitter:emit(Event.Installed)
    return true
  end):next(function(installed)
    installed_now = installed
    return self._revision_switcher:start()
  end):next(function(switched)
    return installed_now or switched
  end)
end

return M
