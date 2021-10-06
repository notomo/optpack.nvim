local Option = require("optpack.core.option").Option
local Loaders = require("optpack.core.loader").Loaders
local Updater = require("optpack.core.updater").Updater
local Installer = require("optpack.core.installer").Installer
local OrderedDict = require("optpack.lib.ordered_dict").OrderedDict

local M = {}

local Package = {}
Package.__index = Package
M.Package = Package

local Packages = {}
Packages.__index = Packages
M.Packages = Packages

function Packages.new()
  local tbl = {_packages = OrderedDict.new()}
  return setmetatable(tbl, Packages)
end

local packages = Packages.new()
function Packages.state()
  return packages
end

function Packages.add(self, name, raw_opts)
  local opts = Option.new(raw_opts)
  if opts.enabled then
    self._packages[name] = Package.new(name, opts)
    opts.hooks.post_add()
  else
    self._packages[name] = nil
  end
end

function Packages.list(self)
  local values = {}
  for _, pack in self._packages:iter() do
    table.insert(values, {name = pack.name, directory = pack.directory})
  end
  return values
end

function Packages.update(self, pattern, outputters)
  -- TODO: limit parallel number
  for _, pack in self._packages:iter() do
    pack:update(outputters)
  end
end

function Packages.load(self, plugin_name)
  for _, pack in self._packages:iter() do
    if pack.plugin_name == plugin_name then
      return pack:load()
    end
  end
end

function Package.new(name, opts)
  vim.validate({name = {name, "string"}, opts = {opts, "table"}})

  -- TODO: select packpath option
  -- TODO: custom package name
  -- TODO: path join
  local opt_path = vim.opt.packpath:get()[1] .. "/pack/optpack/opt/"

  local splitted = vim.split(name, "/", true)
  local plugin_name = splitted[#splitted]
  local directory = opt_path .. plugin_name

  local url = ("%s%s.git"):format(opts.fetch.base_url, name)
  local installer = Installer.new(opts.fetch.engine, opt_path, directory, url, opts.fetch.depth)

  local tbl = {
    name = name,
    plugin_name = plugin_name,
    directory = directory,
    _opt_path = opt_path,
    _hooks = opts.hooks,
    _loaded = false,
    _updater = Updater.new(opts.fetch.engine, installer, directory),
  }
  local self = setmetatable(tbl, Package)

  self._loader_removers = Loaders.set(self, opts.load_on)

  return self
end

function Package.update(self, outputters)
  return self._updater:start(outputters:with({name = self.name}))
end

function Package.load(self)
  if self._loaded then
    return
  end
  self._loaded = true

  self._loader_removers:execute()
  self._hooks.pre_load()
  vim.cmd("packadd " .. self.plugin_name)
  self._hooks.post_load()
end

return M
