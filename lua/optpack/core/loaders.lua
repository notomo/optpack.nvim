local Loader = require("optpack.core.loader")

--- @class OptpackLoaders
--- @field _loaders table<string,OptpackLoader>
--- @field _load_on_installed table<string,boolean>
local Loaders = {}
Loaders.__index = Loaders

function Loaders.new()
  local tbl = {
    _loaders = {},
    _load_on_installed = {},
  }
  return setmetatable(tbl, Loaders)
end

function Loaders.add(self, plugin, opts)
  local loader = Loader.new(plugin, opts.load_on, opts.hooks.pre_load, opts.hooks.post_load)
  if type(loader) == "string" then
    local err = loader
    return err
  end
  self._loaders[plugin.name] = loader
end

function Loaders.remove(self, plugin_name)
  self._loaders[plugin_name] = nil
  self._load_on_installed[plugin_name] = nil
end

function Loaders._load(self, plugin)
  local loader = self._loaders[plugin.name]
  if not loader then
    return nil
  end

  if not plugin:installed() then
    self._load_on_installed[plugin.name] = true
    return nil
  end

  self:remove(plugin.name)

  if not vim.in_fast_event() then
    local err = loader:load()
    return err
  end

  local async = true
  return nil, async
end

function Loaders.sync_load(self, plugin)
  local err, async = self:_load(plugin)
  if err then
    return err
  end
  if not async then
    return nil
  end

  -- fallback
  self:load(plugin)
  return nil
end

function Loaders.load(self, plugin)
  local err, async = self:_load(plugin)
  if err then
    return require("optpack.vendor.promise").reject(err)
  end
  if not async then
    return require("optpack.vendor.promise").resolve()
  end

  local loader = self._loaders[plugin.name]
  return require("optpack.vendor.promise").new(function(resolve, reject)
    vim.schedule(function()
      local load_err = loader:load()
      if load_err then
        reject(load_err)
        return
      end
      resolve()
    end)
  end)
end

function Loaders.load_installed(self, raw_plugins)
  local promises = vim
    .iter(raw_plugins)
    :filter(function(plugin)
      return self._load_on_installed[plugin.name]
    end)
    :map(function(plugin)
      return self:load(plugin)
    end)
    :totable()
  return require("optpack.vendor.promise").all(promises)
end

return Loaders
