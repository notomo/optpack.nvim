local Option = require("optpack.core.option").Option
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

function Plugins.add(self, full_name, raw_opts)
  local opts = Option.new(raw_opts)
  local plugin = Plugin.new(full_name, opts)

  if opts.enabled then
    self._plugins[plugin.name] = plugin
    self._loaders[plugin.name] = Loader.new(plugin.name, opts.load_on, opts.hooks.pre_load, opts.hooks.post_load)
    opts.hooks.post_add()
  else
    self._plugins[plugin.name] = nil
    self._loaders[plugin.name] = nil
    self._load_on_installed[plugin.name] = nil
  end
end

function Plugins.list(self)
  local values = {}
  for _, plugin in self._plugins:iter() do
    table.insert(values, {
      full_name = plugin.full_name,
      name = plugin.name,
      directory = plugin.directory,
      url = plugin.url,
    })
  end
  return values
end

function Plugins.update(self, emitters, pattern, parallel_opts, on_finished)
  emitters:emit(Event.StartUpdate)

  local parallel = ParallelLimitter.new(parallel_opts.limit, parallel_opts.interval)
  for _, plugin in ipairs(self:_collect(pattern)) do
    parallel:add(function()
      return plugin:update(emitters)
    end)
  end

  parallel:start():finally(function()
    emitters:emit(Event.FinishedUpdate)
    on_finished()
  end)
end

function Plugins.install(self, emitters, pattern, parallel_opts, on_finished)
  emitters:emit(Event.StartInstall)

  local parallel = ParallelLimitter.new(parallel_opts.limit, parallel_opts.interval)
  local installed_nows = {}
  for _, plugin in ipairs(self:_collect(pattern)) do
    parallel:add(function()
      return plugin:install(emitters):next(function(installed_now)
        if installed_now then
          table.insert(installed_nows, plugin.name)
        end
      end)
    end)
  end

  parallel:start():finally(function()
    local plugin_names = vim.tbl_filter(function(name)
      return self._load_on_installed[name]
    end, installed_nows)
    for _, plugin_name in ipairs(plugin_names) do
      self:load(plugin_name)
    end

    emitters:emit(Event.FinishedInstall)

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

function Plugin.new(full_name, opts)
  vim.validate({name = {full_name, "string"}, opts = {opts, "table"}})

  local opt_path = pathlib.join(opts.select_packpath(), "pack", opts.package_name, "opt")

  local name = pathlib.tail(full_name)
  local directory = pathlib.join(opt_path, name)

  local url = pathlib.join(opts.fetch.base_url, full_name)
  local git = Git.new(JobFactory.new())
  local installer = Installer.new(git, opt_path, directory, url, opts.fetch.depth)
  local updater = Updater.new(git, installer, directory)

  local tbl = {
    name = name,
    full_name = full_name,
    directory = directory,
    url = url,
    _updater = updater,
    _install = installer,
  }
  return setmetatable(tbl, Plugin)
end

function Plugin.update(self, emitters)
  return self._updater:start(emitters:with({name = self.name})):catch(function(err)
    emitters:emit(Event.Error, err)
  end)
end

function Plugin.install(self, emitters)
  return self._install:start(emitters:with({name = self.name})):catch(function(err)
    emitters:emit(Event.Error, err)
  end)
end

function Plugin.installed(self)
  return vim.fn.isdirectory(self.directory) == 1
end

return M
