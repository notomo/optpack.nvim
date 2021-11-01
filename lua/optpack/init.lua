local Command = require("optpack.command").Command

local M = {}

function M.add(full_name, opts)
  Command.new("add", full_name, opts)
end

function M.list()
  return Command.new("list")
end

function M.update(opts)
  Command.new("update", opts)
end

function M.install(opts)
  Command.new("install", opts)
end

function M.load(plugin_name)
  Command.new("load", plugin_name)
end

function M.set_default(setting)
  Command.new("set_default", setting)
end

return M
