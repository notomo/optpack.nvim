local PluginCollection = require("optpack.core.plugin_collection").PluginCollection
local Plugin = require("optpack.core.plugin").Plugin
local Loaders = require("optpack.core.loaders").Loaders
local Event = require("optpack.core.event").Event
local Counter = require("optpack.lib.counter").Counter
local ParallelLimitter = require("optpack.lib.parallel_limitter").ParallelLimitter

local M = {}

local Plugins = {}
Plugins.__index = Plugins
M.Plugins = Plugins

function Plugins.new()
  local tbl = {_plugins = PluginCollection.new(), _loaders = Loaders.new()}
  return setmetatable(tbl, Plugins)
end

local _state = Plugins.new()
function Plugins.state()
  return _state
end

function Plugins.add(self, full_name, opts)
  local plugin, err = Plugin.new(full_name, opts)
  if err then
    return ("%s: %s"):format(full_name, err)
  end

  if not opts.enabled then
    self._plugins:remove(plugin.name)
    self._loaders:remove(plugin.name)
    return
  end

  self._plugins:add(plugin)
  self._loaders:add(plugin, opts)
  local ok, hook_err = pcall(opts.hooks.post_add, plugin:expose())
  if not ok then
    return ("%s: post_add: %s"):format(plugin.name, hook_err)
  end
end

function Plugins.expose(self)
  return self._plugins:expose()
end

function Plugins.update(self, emitter, pattern, parallel_opts, on_finished)
  emitter:emit(Event.StartUpdate)

  local raw_plugins = self._plugins:collect(pattern)
  local counter = Counter.new(#raw_plugins, function(finished_count, all_count)
    emitter:emit(Event.Progressed, finished_count, all_count)
  end)

  local parallel = ParallelLimitter.new(parallel_opts.limit)
  local names = {}
  for _, plugin in ipairs(raw_plugins) do
    parallel:add(function()
      local plugin_emitter = emitter:with({name = plugin.name})
      return plugin:install_or_update(plugin_emitter):next(function(installed_now)
        if installed_now then
          table.insert(names, plugin.name)
        end
      end):catch(function(err)
        plugin_emitter:emit(Event.Error, err)
      end):finally(function()
        counter = counter:increment()
      end)
    end)
  end

  parallel:start():finally(function()
    local err = self._loaders:load_installed(self._plugins:from(names))
    if err then
      emitter:emit(Event.Error, err)
    end
    emitter:emit(Event.FinishedUpdate)
    on_finished()
  end):catch(function(err)
    emitter:emit(Event.Error, err)
  end)
end

function Plugins.install(self, emitter, pattern, parallel_opts, on_finished)
  emitter:emit(Event.StartInstall)

  local raw_plugins = self._plugins:collect(pattern)
  local counter = Counter.new(#raw_plugins, function(finished_count, all_count)
    emitter:emit(Event.Progressed, finished_count, all_count)
  end)

  local parallel = ParallelLimitter.new(parallel_opts.limit)
  local names = {}
  for _, plugin in ipairs(raw_plugins) do
    parallel:add(function()
      local plugin_emitter = emitter:with({name = plugin.name})
      return plugin:install(plugin_emitter):next(function(installed_now)
        if installed_now then
          table.insert(names, plugin.name)
        end
      end):catch(function(err)
        plugin_emitter:emit(Event.Error, err)
      end):finally(function()
        counter = counter:increment()
      end)
    end)
  end

  parallel:start():finally(function()
    local err = self._loaders:load_installed(self._plugins:from(names))
    if err then
      emitter:emit(Event.Error, err)
    end
    emitter:emit(Event.FinishedInstall)
    on_finished()
  end):catch(function(err)
    emitter:emit(Event.Error, err)
  end)
end

function Plugins.load(self, plugin_name)
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    return nil
  end
  return self._loaders:load(plugin)
end

return M
