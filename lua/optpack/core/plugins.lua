local Plugin = require("optpack.core.plugin").Plugin

--- @class OptpackPlugins
--- @field _plugins OptpackPluginCollection
--- @field _loaders OptpackLoaders
local Plugins = {}
Plugins.__index = Plugins

function Plugins.new()
  local tbl = {
    _plugins = require("optpack.core.plugin_collection").new(),
    _loaders = require("optpack.core.loaders").new(),
  }
  return setmetatable(tbl, Plugins)
end

local _state = Plugins.new()
function Plugins.state()
  return _state
end

function Plugins.add(self, full_name, opts)
  local plugin = Plugin.new(full_name, opts)
  if type(plugin) == "string" then
    local err = plugin
    return ("%s: %s"):format(full_name, err)
  end

  if not opts.enabled then
    self._plugins:remove(plugin.name)
    self._loaders:remove(plugin.name)
    return plugin:expose()
  end

  self._plugins:add(plugin)

  local loader_err = self._loaders:add(plugin, opts)
  if loader_err then
    return ("%s: %s"):format(plugin.name, loader_err)
  end

  local ok, hook_err = pcall(opts.hooks.post_add, plugin:expose())
  if not ok then
    return ("%s: post_add: %s"):format(plugin.name, hook_err)
  end

  return plugin:expose()
end

function Plugins.expose(self)
  return self._plugins:expose()
end

--- @param plugin_name string
function Plugins.expose_one(self, plugin_name)
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    return "not found plugin: " .. plugin_name
  end
  return plugin:expose()
end

--- @param emitter OptpackEventEmitter
function Plugins.install_or_update(self, cmd_type, emitter, pattern, parallel_opts, on_finished)
  local Event = require("optpack.core.event").specific(cmd_type)

  emitter:emit(Event.Start)

  local raw_plugins = self._plugins:collect(pattern)
  local counter = require("optpack.lib.counter").new(#raw_plugins, function(finished_count, all_count)
    emitter:emit(Event.Progressed, finished_count, all_count)
  end)

  local parallel = require("optpack.lib.parallel_limitter").new(parallel_opts.limit)
  local names = {}
  for _, plugin in ipairs(raw_plugins) do
    --- @async
    --- @return nil
    local run_one = function()
      local plugin_emitter = emitter:with({
        name = plugin.name,
        directory = plugin.directory,
      })

      local ok, installed_now = pcall(plugin[cmd_type], plugin, plugin_emitter)
      if not ok then
        local err = installed_now
        plugin_emitter:emit(Event.Error, err)
      elseif installed_now then
        table.insert(names, plugin.name)
      end

      counter = counter:increment()
    end
    parallel:add(run_one)
  end

  --- @async
  --- @return nil
  local run = function()
    --- @async
    --- @return nil
    local run_all = function()
      parallel:start()
      self._loaders:load_installed(self._plugins:from(names))
    end
    local ok, err = pcall(run_all)

    emitter:emit(Event.Finished)
    on_finished()

    if not ok then
      emitter:emit(Event.Error, err)
    end
  end
  vim.async.run(run)
end

function Plugins.sync_load(self, plugin_name)
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    return "not found plugin: " .. plugin_name
  end

  for _, depend in ipairs(plugin.depends) do
    local err = self:sync_load(depend)
    if err then
      return plugin_name .. " depends: " .. err
    end
  end

  return self._loaders:sync_load(plugin)
end

--- @async
--- @return nil
function Plugins.load(self, plugin_name)
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    error("not found plugin: " .. plugin_name, 0)
  end

  local fs = vim
    .iter(plugin.depends)
    :map(function(depend)
      --- @async
      --- @return nil
      return function()
        local ok, err = pcall(self.load, self, depend)
        if not ok then
          error(plugin_name .. " depends: " .. tostring(err), 0)
        end
      end
    end)
    :totable()
  require("optpack.lib.async").all(fs)

  self._loaders:load(plugin)
end

return Plugins
