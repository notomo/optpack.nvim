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
  --- @async
  --- @return nil
  local load = function()
    self:load(plugin)
  end
  vim.async.run(load)
  return nil
end

--- @async
--- @return nil
function Loaders.load(self, plugin)
  local err, async = self:_load(plugin)
  if err then
    error(err, 0)
  end
  if not async then
    return
  end

  local loader = self._loaders[plugin.name]
  vim.async.await(1, vim.schedule)

  local load_err = loader:load()
  if load_err then
    error(load_err, 0)
  end
end

--- @async
--- @return nil
function Loaders.load_installed(self, raw_plugins)
  local fs = vim
    .iter(raw_plugins)
    :filter(function(plugin)
      return self._load_on_installed[plugin.name]
    end)
    :map(function(plugin)
      --- @async
      --- @return nil
      return function()
        self:load(plugin)
      end
    end)
    :totable()
  require("optpack.lib.async").all(fs)
end

return Loaders
