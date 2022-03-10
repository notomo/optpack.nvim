local ReturnValue = require("optpack.lib.error_handler").for_return_value()
local ReturnError = require("optpack.lib.error_handler").for_return_error()

function ReturnError.add(full_name, raw_opts)
  local opts = require("optpack.core.option").AddOption.new(raw_opts)
  return require("optpack.core.plugins").state():add(full_name, opts)
end

function ReturnValue.list()
  return require("optpack.core.plugins").state():expose()
end

function ReturnError.install_or_update(cmd_type, raw_opts)
  local opts, opts_err = require("optpack.core.option").InstallOrUpdateOption.new(raw_opts)
  if opts_err then
    return opts_err
  end

  local outputters, err = require("optpack.view.outputter").new(cmd_type, opts.outputters)
  if err then
    return err
  end
  local emitter = require("optpack.lib.event_emitter").new(outputters)

  return require("optpack.core.plugins").state():install_or_update(
    cmd_type,
    emitter,
    opts.pattern,
    opts.parallel,
    opts.on_finished
  )
end

function ReturnError.load(plugin_name)
  return require("optpack.core.plugins").state():load(plugin_name)
end

function ReturnError.set_default(setting)
  return require("optpack.core.option").set_default(setting)
end

return vim.tbl_extend("force", ReturnValue:methods(), ReturnError:methods())
