local M = {}

--- Add a plugin.
--- @param full_name string: {account_name}/{plugin_name} format
--- @param opts table|nil: |optpack.nvim-add-option|
function M.add(full_name, opts)
  require("optpack.command").add(full_name, opts)
end

--- Returns list of plugins.
--- @return table: list of |optpack.nvim-plugin|
function M.list()
  return require("optpack.command").list()
end

--- Returns a plugin.
--- @param plugin_name string:
--- @return table: |optpack.nvim-plugin|
function M.get(plugin_name)
  return require("optpack.command").get(plugin_name)
end

--- Install plugins.
--- @param opts table|nil: |optpack.nvim-install-or-update-option|
function M.install(opts)
  require("optpack.command").install_or_update("install", opts)
end

--- Update plugins.
--- @param opts table|nil: |optpack.nvim-install-or-update-option|
function M.update(opts)
  require("optpack.command").install_or_update("update", opts)
end

--- Load a plugin.
--- @param plugin_name string:
function M.load(plugin_name)
  require("optpack.command").load(plugin_name)
end

-- helper
function M.load_by_expr_keymap(...)
  M.load(...)
  return ""
end

--- Set default setting.
--- @param setting table: |optpack.nvim-setting|
function M.set_default(setting)
  require("optpack.command").set_default(setting)
end

return M
