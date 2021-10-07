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
    return nil
  end

  local ok, err = pcall(vim.fn.mkdir, self._opt_path, "p")
  if not ok then
    return outputters:with({event_name = "prepare_install"}):error(err)
  end
  return self._engine:clone(outputters, self._directory, self._url, self._depth)
end

return M
