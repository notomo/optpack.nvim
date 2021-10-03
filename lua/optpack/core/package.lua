local Loaders = require("optpack.core.loader").Loaders
local Option = require("optpack.core.option").Option
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
  for _, pack in ipairs(self._packages) do
    pack:update()
  end
end

function Package.new(name, opts)
  vim.validate({name = {name, "string"}, opts = {opts, "table"}})

  -- TODO: hook
  Loaders.set(name, opts.load_on)

  local tbl = {name = name}
  return setmetatable(tbl, Package)
end

function Package.update(self)
  -- TODO
end

return M
