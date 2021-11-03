local Loader = require("optpack.core.loader").Loader
local Updater = require("optpack.core.updater").Updater
local Installer = require("optpack.core.installer").Installer
local Event = require("optpack.core.event").Event
local OrderedDict = require("optpack.lib.ordered_dict").OrderedDict
local ParallelLimitter = require("optpack.lib.parallel_limitter").ParallelLimitter
local JobFactory = require("optpack.lib.job_factory").JobFactory
local Git = require("optpack.lib.git").Git
local pathlib = require("optpack.lib.path")

local M = {}

local Plugin = {}
Plugin.__index = Plugin
M.Plugin = Plugin

local Plugins = {}
Plugins.__index = Plugins
M.Plugins = Plugins

function Plugins.new()
  local tbl = {_plugins = OrderedDict.new(), _loaders = {}, _load_on_installed = {}}
  return setmetatable(tbl, Plugins)
end

local _plugins = Plugins.new()
function Plugins.state()
  return _plugins
end

function Plugins.add(self, full_name, opts)
  local plugin = Plugin.new(full_name, opts)
  if opts.enabled then
    self._plugins[plugin.name] = plugin
    self._loaders[plugin.name] = Loader.new(plugin, opts.load_on, opts.hooks.pre_load, opts.hooks.post_load)
    opts.hooks.post_add(plugin:expose())
  else
    self._plugins[plugin.name] = nil
    self._loaders[plugin.name] = nil
    self._load_on_installed[plugin.name] = nil
  end
end

function Plugins.list(self)
  local values = {}
  for _, plugin in self._plugins:iter() do
    table.insert(values, plugin:expose())
  end
  return values
end

function Plugins.update(self, emitter, pattern, parallel_opts, on_finished)
  emitter:emit(Event.StartUpdate)

  local parallel = ParallelLimitter.new(parallel_opts.limit, parallel_opts.interval)
  local names = {}
  for _, plugin in ipairs(self:_collect(pattern)) do
    parallel:add(function()
      return plugin:install_or_update(emitter):next(function(installed_now)
        if installed_now then
          table.insert(names, plugin.name)
        end
      end)
    end)
  end

  parallel:start():finally(function()
    self:_load_installed(names)
    emitter:emit(Event.FinishedUpdate)
    on_finished()
  end)
end

function Plugins.install(self, emitter, pattern, parallel_opts, on_finished)
  emitter:emit(Event.StartInstall)

  local parallel = ParallelLimitter.new(parallel_opts.limit, parallel_opts.interval)
  local names = {}
  for _, plugin in ipairs(self:_collect(pattern)) do
    parallel:add(function()
      return plugin:install(emitter):next(function(installed_now)
        if installed_now then
          table.insert(names, plugin.name)
        end
      end)
    end)
  end

  parallel:start():finally(function()
    self:_load_installed(names)
    emitter:emit(Event.FinishedInstall)
    on_finished()
  end)
end

function Plugins.load(self, plugin_name)
  local plugin = self:find(function(p)
    return p.name == plugin_name
  end)
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

function Plugins.find(self, f)
  for _, plugin in self._plugins:iter() do
    if f(plugin) then
      return plugin
    end
  end
end

function Plugins._collect(self, pattern)
  local raw_plugins = {}
  local regex = vim.regex(pattern)
  for _, plugin in self._plugins:iter() do
    if regex:match_str(plugin.name) then
      table.insert(raw_plugins, plugin)
    end
  end
  return raw_plugins
end

function Plugins._load_installed(self, plugin_names)
  local names = vim.tbl_filter(function(name)
    return self._load_on_installed[name]
  end, plugin_names)
  for _, plugin_name in ipairs(names) do
    self:load(plugin_name)
  end
end

function Plugin.new(full_name, opts)
  vim.validate({name = {full_name, "string"}, opts = {opts, "table"}})

  local name = pathlib.tail(full_name)
  local directory = pathlib.join(opts.select_packpath(), "pack", opts.package_name, "opt", name)
  local git = Git.new(JobFactory.new())
  local url = pathlib.join(opts.fetch.base_url, full_name)

  local tbl = {
    name = name,
    full_name = full_name,
    directory = directory,
    url = url,
    _installer = Installer.new(git, directory, url, opts.fetch.depth),
    _post_install_hook = opts.hooks.post_install,
    _updater = Updater.new(git, directory),
    _post_update_hook = opts.hooks.post_update,
  }
  return setmetatable(tbl, Plugin)
end

function Plugin.expose(self)
  return {full_name = self.full_name, name = self.name, directory = self.directory, url = self.url}
end

function Plugin.install_or_update(self, emitter)
  if not self:installed() then
    return self:install(emitter)
  end
  return self:update(emitter):next(function()
    return false
  end)
end

function Plugin.update(self, emitter)
  return self._updater:start(emitter:with({name = self.name})):next(function(updated_now)
    if updated_now then
      self._post_update_hook(self:expose())
    end
    return updated_now
  end):catch(function(err)
    emitter:emit(Event.Error, err)
  end)
end

function Plugin.install(self, emitter)
  return self._installer:start(emitter:with({name = self.name})):next(function(installed_now)
    if installed_now then
      self._post_install_hook(self:expose())
    end
    return installed_now
  end):catch(function(err)
    emitter:emit(Event.Error, err)
  end)
end

function Plugin.installed(self)
  return self._installer:already()
end

return M
