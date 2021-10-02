local Command = require("optpack.command").Command

local M = {}

function M.add(name, opts)
  Command.new("add", name, opts)
end

function M.list()
  return Command.new("list")
end

function M.update(pattern)
  Command.new("update", pattern)
end

return M
