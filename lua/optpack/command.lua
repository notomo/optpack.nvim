local ReturnValue = require("optpack.vendor.misclib.error_handler").for_return_value()
local ShowError = require("optpack.vendor.misclib.error_handler").for_show_error()

local AddOption = require("optpack.core.option").AddOption
local Plugins = require("optpack.core.plugins")

function ShowError.add(full_name, raw_opts)
  local opts = AddOption.new(raw_opts)
  return Plugins.state():add(full_name, opts)
end

function ReturnValue.list()
  return Plugins.state():expose()
end

function ReturnValue.get(plugin_name)
  return Plugins.state():expose_one(plugin_name)
end

function ShowError.install_or_update(cmd_type, raw_opts)
  local opts, opts_err = require("optpack.core.option").InstallOrUpdateOption.new(raw_opts)
  if opts_err then
    return opts_err
  end

  local outputters, err = require("optpack.view.outputter").new(cmd_type, opts.outputters)
  if err then
    return err
  end
  local emitter = require("optpack.lib.event_emitter").new(outputters)

  return Plugins.state():install_or_update(cmd_type, emitter, opts.pattern, opts.parallel, opts.on_finished)
end

function ShowError.load(plugin_name)
  return Plugins.state():load(plugin_name)
end

function ShowError.set_default(setting)
  return require("optpack.core.option").set_default(setting)
end

return vim.tbl_extend("force", ReturnValue:methods(), ShowError:methods())
