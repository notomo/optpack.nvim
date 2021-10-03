local M = {}

local OnModule = {}
OnModule.__index = OnModule
M.OnModule = OnModule

local OnModules = {}
OnModules.__index = OnModules
M.OnModules = OnModules

function OnModules.set(pack, module_names)
  for _, module_name in ipairs(module_names) do
    OnModule.new(pack, module_name)
  end
end

function OnModule.new(pack, module_name)
  local tbl = {_pack = pack, _module_name = module_name, _loaded = false}
  local self = setmetatable(tbl, OnModule)

  self._f = function(required_name)
    local ok = self:_set(required_name)
    self:_hook_post(ok)
  end
  table.insert(package.loaders, 1, self._f)
end

function OnModule._set(self, required_name)
  if self._loaded then
    return false
  end

  local name = vim.split(required_name:gsub("/", "."), ".", true)[1]
  if self._module_name ~= name then
    return false
  end
  self._loaded = true

  self._pack:hook_pre_load()
  self._pack:load_only()

  vim.schedule(function()
    self:_remove()
  end)

  return true
end

function OnModule._hook_post(self, ok)
  if not ok then
    return
  end
  self._pack:hook_post_load()
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
