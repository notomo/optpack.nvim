local Option = require("optpack.core.option").Option
local Loaders = require("optpack.core.loader").Loaders
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
    -- TODO: dir
    table.insert(values, {name = pack.name})
  end
  return values
end

function Packages.update(self)
  -- TODO
  for _, pack in self._packages:iter() do
    pack:update()
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

  local splitted = vim.split(name, "/", true)
  local plugin_name = splitted[#splitted]
  local tbl = {name = name, plugin_name = plugin_name, _hooks = opts.hooks}
  local self = setmetatable(tbl, Package)

  Loaders.set(self, opts.load_on)

  return self
end

function Package.update(self)
  -- TODO
end

function Package.load(self)
  self._hooks.pre_load()
  vim.cmd("packadd " .. self.plugin_name)
  self._hooks.post_load()
end

return M
