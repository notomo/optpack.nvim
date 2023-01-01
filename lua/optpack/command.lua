local M = {}

local AddOption = require("optpack.core.option").AddOption
local Plugins = require("optpack.core.plugins")

function M.add(full_name, raw_opts)
  local opts = AddOption.new(raw_opts)
  local err = Plugins.state():add(full_name, opts)
  if err then
    require("optpack.vendor.misclib.message").error(err)
  end
end

function M.list()
  local plugins, err = Plugins.state():expose()
  if err then
    require("optpack.vendor.misclib.message").error(err)
  end
  return plugins
end

function M.get(plugin_name)
  local plugin, err = Plugins.state():expose_one(plugin_name)
  if err then
    require("optpack.vendor.misclib.message").error(err)
  end
  return plugin
end

function M.install_or_update(cmd_type, raw_opts)
  local opts, opts_err = require("optpack.core.option").InstallOrUpdateOption.new(raw_opts)
  if opts_err then
    require("optpack.vendor.misclib.message").error(opts_err)
  end

  local outputters, err = require("optpack.view.outputter").new(cmd_type, opts.outputters)
  if err then
    require("optpack.vendor.misclib.message").error(err)
  end
  local emitter = require("optpack.lib.event_emitter").new(outputters)

  return Plugins.state():install_or_update(cmd_type, emitter, opts.pattern, opts.parallel, opts.on_finished)
end

function M.load(plugin_name)
  local err = Plugins.state():load(plugin_name)
  if err then
    require("optpack.vendor.misclib.message").error(err)
  end
end

function M.set_default(setting)
  require("optpack.core.option").set_default(setting)
end

return M
