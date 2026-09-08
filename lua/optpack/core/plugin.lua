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

--- @async
function Plugin.update(self, emitter)
  if not self:installed() then
    return self:install(emitter)
  end
  self:_update(emitter)
  return false
end

--- @async
function Plugin._update(self, emitter)
  local updated_now = require("optpack.core.updater").start(emitter, self.directory, self._version)
  if updated_now then
    ---@diagnostic disable-next-line: invisible
    self._post_update_hook(self:expose())
  end
  return updated_now
end

--- @async
function Plugin.install(self, emitter)
  local installed_now =
    require("optpack.core.installer").start(emitter, self.directory, self.url, self._depth, self._version)
  if installed_now then
    ---@diagnostic disable-next-line: invisible
    self._post_install_hook(self:expose())
  end
  return installed_now
end

function Plugin.installed(self)
  return require("optpack.core.installer").already(self.directory)
end

return M
