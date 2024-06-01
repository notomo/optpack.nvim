local OnModule = {}
OnModule.__index = OnModule

local OnModules = {}

function OnModules.set(plugin_name, module_names)
  OnModules._cleanup(plugin_name)
  local removers = {}
  for _, module_name in ipairs(module_names) do
    table.insert(removers, OnModule.new(plugin_name, module_name))
  end
  return removers
end

function OnModules._cleanup(plugin_name)
  local indexes = {}
  for i, loader in ipairs(package.loaders) do
    if type(loader) == "table" and loader.optpack_plugin_name == plugin_name then
      table.insert(indexes, i)
    end
  end
  for _, index in ipairs(vim.fn.reverse(indexes)) do
    table.remove(package.loaders, index)
  end
end

function OnModule.new(plugin_name, module_name)
  local tbl = { _plugin_name = plugin_name, _module_name = module_name, _loaded = false }
  local self = setmetatable(tbl, OnModule)

  self._f = setmetatable({ optpack_plugin_name = plugin_name }, {
    __call = function(_, required_name)
      self:_set(required_name)
    end,
  })
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

  required_name = required_name:gsub("/", ".")
  local splitted = vim.split(required_name, ".", { plain = true })
  local ok = false
  for i in ipairs(splitted) do
    local module_name = table.concat(vim.list_slice(splitted, 1, i), ".")
    if module_name == self._module_name then
      ok = true
      break
    end
  end
  if not ok then
    return
  end
  self._loaded = true

  require("optpack.command").sync_load(self._plugin_name)

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

return OnModules
