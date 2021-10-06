local Option = require("optpack.core.option").Option
local Loaders = require("optpack.core.loader").Loaders
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
  local tbl = {_plugins = OrderedDict.new()}
  return setmetatable(tbl, Plugins)
end

local plugins = Plugins.new()
function Plugins.state()
  return plugins
end

function Plugins.add(self, full_name, raw_opts)
  local opts = Option.new(raw_opts)

  if opts.enabled then
    local plugin = Plugin.new(full_name, opts)
    self._plugins[plugin.name] = plugin
    opts.hooks.post_add()
    return
  end

  local plugin = self:find(function(p)
    return p.full_name == full_name
  end)
  if plugin then
    self._plugins[plugin.name] = nil
  end
end

function Plugins.find(self, f)
  for _, plugin in self._plugins:iter() do
    if f(plugin) then
      return plugin
    end
  end
  return nil
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
  for _, plugin in self._plugins:iter() do
    if plugin.name == plugin_name then
      return plugin:load()
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
    _opt_path = opt_path,
    _hooks = opts.hooks,
    _loaded = false,
    _updater = Updater.new(opts.fetch.engine, installer, directory),
  }
  local self = setmetatable(tbl, Plugin)

  self._loader_removers = Loaders.set(self, opts.load_on)

  return self
end

function Plugin.update(self, outputters)
  return self._updater:start(outputters:with({name = self.name}))
end

function Plugin.load(self)
  if self._loaded then
    return
  end
  self._loaded = true

  self._loader_removers:execute()
  self._hooks.pre_load()
  vim.cmd("packadd " .. self.name)
  self._hooks.post_load()
end

return M
