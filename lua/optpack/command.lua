local Packages = require("optpack.core.package").Packages
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

function Command.add(name, opts)
  return Packages.state():add(name, opts)
end

function Command.list()
  return Packages.state():list()
end

function Command.update(pattern)
  return Packages.state():update(pattern)
end

function Command.load(plugin_name)
  return Packages.state():load(plugin_name)
end

return M
