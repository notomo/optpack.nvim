local Command = require("optpack.command").Command

local M = {}

--- Add a plugin.
--- @param full_name string: {account_name}/{plugin_name} format
--- @param opts table|nil: |optpack.nvim-add-option|
function M.add(full_name, opts)
  Command.new("add", full_name, opts)
end

--- Returns list of plugins.
--- @return table: list of |optpack.nvim-plugin|
function M.list()
  return Command.new("list")
end

--- Install plugins.
--- @param opts table|nil: |optpack.nvim-install-or-update-option|
function M.install(opts)
  Command.new("install", opts)
end

--- Update plugins.
--- @param opts table|nil: |optpack.nvim-install-or-update-option|
function M.update(opts)
  Command.new("update", opts)
end

--- Load a plugin.
--- @param plugin_name string:
function M.load(plugin_name)
  Command.new("load", plugin_name)
end

--- Set default setting.
--- @param setting table: |optpack.nvim-setting|
function M.set_default(setting)
  Command.new("set_default", setting)
end

return M
