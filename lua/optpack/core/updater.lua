local M = {}

local Updater = {}
Updater.__index = Updater
M.Updater = Updater

function Updater.new(engine, installer, directory)
  vim.validate({
    engine = {engine, "table"},
    installer = {installer, "table"},
    directory = {directory, "string"},
  })
  local tbl = {_engine = engine, _installer = installer, _directory = directory}
  return setmetatable(tbl, Updater)
end

function Updater.start(self, outputters)
  if not self._installer:already() then
    return self._installer:start(outputters)
  end
  return self._engine:pull(outputters, self._directory)
end

return M
