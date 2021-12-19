local PluginCollection = require("optpack.core.plugin_collection").PluginCollection
local Plugin = require("optpack.core.plugin").Plugin
local Loader = require("optpack.core.loader").Loader
local Event = require("optpack.core.event").Event
local Counter = require("optpack.lib.counter").Counter
local ParallelLimitter = require("optpack.lib.parallel_limitter").ParallelLimitter

local M = {}

local Plugins = {}
Plugins.__index = Plugins
M.Plugins = Plugins

function Plugins.new()
  local tbl = {_plugins = PluginCollection.new(), _loaders = {}, _load_on_installed = {}}
  return setmetatable(tbl, Plugins)
end

local _plugins = Plugins.new()
function Plugins.state()
  return _plugins
end

function Plugins.add(self, full_name, opts)
  local plugin = Plugin.new(full_name, opts)
  if opts.enabled then
    self._plugins:add(plugin)
    self._loaders[plugin.name] = Loader.new(plugin, opts.load_on, opts.hooks.pre_load, opts.hooks.post_load)
    local ok, err = pcall(opts.hooks.post_add, plugin:expose())
    if not ok then
      return ("%s: post_add: %s"):format(plugin.name, err)
    end
  else
    self._plugins:remove(plugin.name)
    self._loaders[plugin.name] = nil
    self._load_on_installed[plugin.name] = nil
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
    self:_load_installed(names)
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
    self:_load_installed(names)
    emitter:emit(Event.FinishedInstall)
    on_finished()
  end):catch(function(err)
    emitter:emit(Event.Error, err)
  end)
end

function Plugins.load(self, plugin_name)
  local plugin = self._plugins:find_by_name(plugin_name)
  if not plugin then
    return
  end

  local loader = self._loaders[plugin.name]
  if not loader then
    return
  end

  if not plugin:installed() then
    self._load_on_installed[plugin.name] = true
    return
  end

  self._loaders[plugin.name] = nil
  self._load_on_installed[plugin.name] = nil

  return loader:load()
end

function Plugins._load_installed(self, plugin_names)
  local names = vim.tbl_filter(function(name)
    return self._load_on_installed[name]
  end, plugin_names)

  local errs = {}
  for _, plugin_name in ipairs(names) do
    local err = self:load(plugin_name)
    if err then
      table.insert(errs, err)
    end
  end
  if #errs ~= 0 then
    return table.concat(errs, "\n")
  end
end

return M
