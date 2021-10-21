local Promise = require("optpack.lib.promise").Promise

local M = {}

local Installer = {}
Installer.__index = Installer
M.Installer = Installer

function Installer.new(engine, opt_path, directory, url, depth)
  vim.validate({
    engine = {engine, "table"},
    opt_path = {opt_path, "string"},
    directory = {directory, "string"},
    url = {url, "string"},
    depth = {depth, "number"},
  })
  local tbl = {
    _engine = engine,
    _opt_path = opt_path,
    _directory = directory,
    _url = url,
    _depth = depth,
  }
  return setmetatable(tbl, Installer)
end

function Installer.already(self)
  return vim.fn.isdirectory(self._directory) ~= 0
end

function Installer.start(self, outputters)
  if self:already() then
    return Promise.resolve(false)
  end

  local ok, err = pcall(vim.fn.mkdir, self._opt_path, "p")
  if not ok then
    return Promise.reject(err)
  end
  return self._engine:clone(self._directory, self._url, self._depth):next(function(lines)
    outputters:with({speaker = "git"}):info("clone", lines)
    outputters:info("installed")
    return true
  end):catch(function(lines)
    outputters:error("error", lines)
  end)
end

return M
