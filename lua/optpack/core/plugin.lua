local M = {}

--- @class OptpackInternalPlugin
--- @field name string
--- @field full_name string
--- @field directory string
--- @field url string
--- @field private _opts table
--- @field private _version string
--- @field private _depth integer
--- @field private _post_update_hook fun(plugin:OptpackPlugin)
--- @field private _post_install_hook fun(plugin:OptpackPlugin)
local Plugin = {}
Plugin.__index = Plugin
M.Plugin = Plugin

--- @param full_name string
--- @param opts table
--- @return OptpackInternalPlugin|string
function Plugin.new(full_name, opts)
  local name = vim.fs.basename(full_name)
  local packpath = opts.select_packpath()
  if not packpath or packpath == "" then
    return "`select_packpath` should return non-empty string"
  end
  local directory = vim.fs.normalize(vim.fs.joinpath(packpath, "pack", opts.package_name, "opt", name))
  local url = opts.fetch.base_url .. "/" .. full_name

  local tbl = {
    name = name,
    full_name = full_name,
    directory = directory,
    url = url,
    depends = opts.depends,
    _version = opts.fetch.version,
    _post_install_hook = opts.hooks.post_install,
    _post_update_hook = opts.hooks.post_update,
    _depth = opts.fetch.depth,
    _opts = opts,
  }
  return setmetatable(tbl, Plugin)
end

--- @return OptpackPlugin
function Plugin.expose(self)
  return {
    full_name = self.full_name,
    name = self.name,
    directory = self.directory,
    version = self._version,
    url = self.url,
    opts = self._opts,
  }
end

function Plugin.update(self, emitter)
  if not self:installed() then
    return self:install(emitter)
  end
  return self:_update(emitter):next(function()
    return false
  end)
end

function Plugin._update(self, emitter)
  return require("optpack.core.updater").start(emitter, self.directory, self._version):next(function(updated_now)
    if updated_now then
      ---@diagnostic disable-next-line: invisible
      self._post_update_hook(self:expose())
    end
    return updated_now
  end)
end

function Plugin.install(self, emitter)
  return require("optpack.core.installer")
    .start(emitter, self.directory, self.url, self._depth, self._version)
    :next(function(installed_now)
      if installed_now then
        ---@diagnostic disable-next-line: invisible
        self._post_install_hook(self:expose())
      end
      return installed_now
    end)
end

function Plugin.installed(self)
  return require("optpack.core.installer").already(self.directory)
end

return M
