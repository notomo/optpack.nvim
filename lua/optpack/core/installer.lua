local Event = require("optpack.core.event").Event
local Promise = require("optpack.lib.promise").Promise

local M = {}

local Installer = {}
Installer.__index = Installer
M.Installer = Installer

function Installer.new(git, opt_path, directory, url, depth)
  vim.validate({
    git = {git, "table"},
    opt_path = {opt_path, "string"},
    directory = {directory, "string"},
    url = {url, "string"},
    depth = {depth, "number"},
  })
  local tbl = {_git = git, _opt_path = opt_path, _directory = directory, _url = url, _depth = depth}
  return setmetatable(tbl, Installer)
end

function Installer.already(self)
  return vim.fn.isdirectory(self._directory) ~= 0
end

function Installer.start(self, emitters)
  if self:already() then
    return Promise.resolve(false)
  end

  local ok, mkdir_err = pcall(vim.fn.mkdir, self._opt_path, "p")
  if not ok then
    return Promise.reject(mkdir_err)
  end

  return self._git:clone(self._directory, self._url, self._depth):next(function(output)
    emitters:emit(Event.GitCloned, output)
    emitters:emit(Event.Installed)
    return true
  end):catch(function(err)
    emitters:emit(Event.Error, err)
  end)
end

return M
