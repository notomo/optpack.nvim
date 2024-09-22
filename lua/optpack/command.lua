local M = {}

local AddOption = require("optpack.core.option").AddOption
local Plugins = require("optpack.core.plugins")

function M.add(full_name, raw_opts)
  local opts = AddOption.new(raw_opts)
  local plugin = Plugins.state():add(full_name, opts)
  if type(plugin) == "string" then
    local err = plugin
    error(require("optpack.vendor.misclib.message").wrap(err), 0)
  end
  return plugin
end

function M.list()
  return Plugins.state():expose()
end

function M.get(plugin_name)
  local plugin = Plugins.state():expose_one(plugin_name)
  if type(plugin) == "string" then
    local err = plugin
    error(require("optpack.vendor.misclib.message").wrap(err), 0)
  end
  return plugin
end

function M.install_or_update(cmd_type, raw_opts)
  local opts = require("optpack.core.option").InstallOrUpdateOption.new(raw_opts)
  if type(opts) == "string" then
    local err = opts
    error(require("optpack.vendor.misclib.message").wrap(err), 0)
  end

  local outputters = require("optpack.view.outputter").new(cmd_type, opts.outputters)
  if type(outputters) == "string" then
    local err = outputters
    error(require("optpack.vendor.misclib.message").wrap(err), 0)
  end
  local emitter = require("optpack.lib.event_emitter").new(outputters)

  return Plugins.state():install_or_update(cmd_type, emitter, opts.pattern, opts.parallel, opts.on_finished)
end

function M.load(plugin_name, raw_opts)
  local opts = require("optpack.core.option").LoadOption.new(raw_opts)
  Plugins.state()
    :load(plugin_name)
    :catch(function(err)
      require("optpack.vendor.misclib.message").warn(err)
    end)
    :finally(function()
      opts.on_finished()
    end)
end

function M.sync_load(plugin_name)
  local err = Plugins.state():sync_load(plugin_name)
  if err then
    error(require("optpack.vendor.misclib.message").wrap(err), 0)
  end
end

function M.sync_load_by_expr_keymap(plugin_name)
  require("optpack.command").sync_load(plugin_name)
  return ""
end

function M.set_default(setting)
  require("optpack.core.option").set_default(setting)
end

return M
