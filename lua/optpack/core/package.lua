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
    table.insert(values, {name = pack.name, directory = pack.directory})
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

  -- TODO: select packpath option
  -- TODO: path join
  local opt_path = vim.opt.packpath:get()[1] .. "/pack/optpack/opt/"

  local splitted = vim.split(name, "/", true)
  local plugin_name = splitted[#splitted]
  local tbl = {
    name = name,
    plugin_name = plugin_name,
    directory = opt_path .. plugin_name,
    _opt_path = opt_path,
    _hooks = opts.hooks,
    _loaded = false,
    _fetch_engine = opts.fetch.engine,
    _fetch_depth = opts.fetch.depth,
    _url = ("%s%s.git"):format(opts.fetch.base_url, name),
  }
  local self = setmetatable(tbl, Package)

  self._loader_removers = Loaders.set(self, opts.load_on)

  return self
end

function Package.update(self)
  -- TODO: open view
  local err = self:_ensure_installed()
  if err then
    return err
  end
  return self._fetch_engine:pull(self.directory)
end

function Package._ensure_installed(self)
  if vim.fn.isdirectory(self.directory) ~= 0 then
    return nil
  end
  -- TODO: mkdir once
  vim.fn.mkdir(self._opt_path, "p")
  return self._fetch_engine:clone(self.directory, self._url, self._fetch_depth)
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
