local Updater = require("optpack.core.updater").Updater
local Installer = require("optpack.core.installer").Installer
local Event = require("optpack.core.event").Event
local JobFactory = require("optpack.lib.job_factory").JobFactory
local Git = require("optpack.lib.git").Git
local pathlib = require("optpack.lib.path")

local M = {}

local Plugin = {}
Plugin.__index = Plugin
M.Plugin = Plugin

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
