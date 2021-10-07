local Option = require("optpack.core.option").Option
local Loader = require("optpack.core.loader").Loader
local Updater = require("optpack.core.updater").Updater
local Installer = require("optpack.core.installer").Installer
local OrderedDict = require("optpack.lib.ordered_dict").OrderedDict

local M = {}

local Plugin = {}
Plugin.__index = Plugin
M.Plugin = Plugin

local Plugins = {}
Plugins.__index = Plugins
M.Plugins = Plugins

function Plugins.new()
  local tbl = {_plugins = OrderedDict.new(), _loaders = {}}
  return setmetatable(tbl, Plugins)
end

local plugins = Plugins.new()
function Plugins.state()
  return plugins
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
  end
end

function Plugins.list(self)
  local values = {}
  for _, plugin in self._plugins:iter() do
    table.insert(values, {
      full_name = plugin.full_name,
      name = plugin.name,
      directory = plugin.directory,
    })
  end
  return values
end

function Plugins.update(self, pattern, outputters)
  -- TODO: limit parallel number
  for _, plugin in self._plugins:iter() do
    plugin:update(outputters)
  end
end

function Plugins.load(self, plugin_name)
  local plugin = self:find(function(p)
    return p.name == plugin_name
  end)
  local loader = self._loaders[plugin.name]
  if loader then
    self._loaders[plugin.name] = nil
    return loader:load()
  end
end

function Plugins.find(self, f)
  for _, plugin in self._plugins:iter() do
    if f(plugin) then
      return plugin
    end
  end
end

function Plugin.new(full_name, opts)
  vim.validate({name = {full_name, "string"}, opts = {opts, "table"}})

  -- TODO: select packpath option
  -- TODO: custom plugin name
  -- TODO: path join
  local opt_path = vim.opt.packpath:get()[1] .. "/pack/optpack/opt/"

  local splitted = vim.split(full_name, "/", true)
  local name = splitted[#splitted]
  local directory = opt_path .. name

  local url = ("%s%s.git"):format(opts.fetch.base_url, full_name)
  local installer = Installer.new(opts.fetch.engine, opt_path, directory, url, opts.fetch.depth)

  local tbl = {
    name = name,
    full_name = full_name,
    directory = directory,
    _updater = Updater.new(opts.fetch.engine, installer, directory),
  }
  return setmetatable(tbl, Plugin)
end

function Plugin.update(self, outputters)
  return self._updater:start(outputters:with({name = self.name}))
end

return M
