local Loader = require("optpack.core.loader")

local Loaders = {}
Loaders.__index = Loaders

function Loaders.new()
  local tbl = { _loaders = {}, _load_on_installed = {} }
  return setmetatable(tbl, Loaders)
end

function Loaders.add(self, plugin, opts)
  local loader, err = Loader.new(plugin, opts.load_on, opts.hooks.pre_load, opts.hooks.post_load)
  if err then
    return err
  end
  self._loaders[plugin.name] = loader
end

function Loaders.remove(self, plugin_name)
  self._loaders[plugin_name] = nil
  self._load_on_installed[plugin_name] = nil
end

function Loaders.load(self, plugin)
  local loader = self._loaders[plugin.name]
  if not loader then
    return nil
  end

  if not plugin:installed() then
    self._load_on_installed[plugin.name] = true
    return nil
  end

  self:remove(plugin.name)

  return loader:load()
end

function Loaders.load_installed(self, raw_plugins)
  raw_plugins = vim
    .iter(raw_plugins)
    :filter(function(plugin)
      return self._load_on_installed[plugin.name]
    end)
    :totable()

  local errs = {}
  for _, plugin in ipairs(raw_plugins) do
    local err = self:load(plugin)
    if err then
      table.insert(errs, err)
    end
  end
  if #errs ~= 0 then
    return table.concat(errs, "\n")
  end
end

return Loaders
