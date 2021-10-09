local Command = require("optpack.command").Command

local M = {}

function M.add(full_name, opts)
  Command.new("add", full_name, opts)
end

function M.list()
  return Command.new("list")
end

function M.update(pattern, on_finished)
  Command.new("update", pattern, on_finished)
end

function M.install(pattern, on_finished)
  Command.new("install", pattern, on_finished)
end

function M.load(plugin_name)
  Command.new("load", plugin_name)
end

return M
