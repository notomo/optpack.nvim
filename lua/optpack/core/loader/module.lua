local M = {}

local OnModule = {}
OnModule.__index = OnModule
M.OnModule = OnModule

local OnModules = {}
OnModules.__index = OnModules
M.OnModules = OnModules

function OnModules.set(pack, module_names)
  local removers = {}
  for _, module_name in ipairs(module_names) do
    table.insert(removers, OnModule.new(pack, module_name))
  end
  return removers
end

function OnModule.new(pack, module_name)
  local tbl = {_pack = pack, _module_name = module_name, _loaded = false}
  local self = setmetatable(tbl, OnModule)

  self._f = function(required_name)
    self:_set(required_name)
  end
  table.insert(package.loaders, 1, self._f)

  return function()
    vim.schedule(function()
      self:_remove()
    end)
  end
end

function OnModule._set(self, required_name)
  if self._loaded then
    return
  end

  local name = vim.split(required_name:gsub("/", "."), ".", true)[1]
  if self._module_name ~= name then
    return
  end
  self._loaded = true

  self._pack:load()

  vim.schedule(function()
    self:_remove()
  end)
end

function OnModule._remove(self)
  local index
  for i, loader in ipairs(package.loaders) do
    if loader == self._f then
      index = i
      break
    end
  end
  if index then
    table.remove(package.loaders, index)
  end
end

return M
