local Plugins = require("optpack.core.plugin").Plugins
local Outputters = require("optpack.view.outputter").Outputters
local messagelib = require("optpack.lib.message")

local M = {}

local Command = {}
Command.__index = Command
M.Command = Command

function Command.new(name, ...)
  local args = vim.F.pack_len(...)
  local f = function()
    return Command[name](vim.F.unpack_len(args))
  end

  local ok, result, msg = xpcall(f, debug.traceback)
  if not ok then
    return messagelib.error(result)
  elseif msg then
    return messagelib.warn(msg)
  end
  return result
end

function Command.add(full_name, opts)
  return Plugins.state():add(full_name, opts)
end

function Command.list()
  return Plugins.state():list()
end

-- TODO: as update opts
function Command.update(pattern, on_finished)
  vim.validate({on_finished = {on_finished, "function", true}})
  on_finished = on_finished or function()
  end

  -- TODO: custom outputter types
  local outputters, err = Outputters.from({"buffer"})
  if err then
    return err
  end
  return Plugins.state():update(pattern, outputters, on_finished)
end

-- TODO: as install opts
function Command.install(pattern, on_finished)
  vim.validate({on_finished = {on_finished, "function", true}})
  on_finished = on_finished or function()
  end

  -- TODO: custom outputter types
  local outputters, err = Outputters.from({"buffer"})
  if err then
    return err
  end
  return Plugins.state():install(pattern, outputters, on_finished)
end

function Command.load(plugin_name)
  return Plugins.state():load(plugin_name)
end

return M
