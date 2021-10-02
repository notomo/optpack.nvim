local OnEvents = require("optpack.core.loader.event").OnEvents

local M = {}

local OnCommands = {}
OnCommands.__index = OnCommands
M.OnCommands = OnCommands

function OnCommands.set(plugin_name, cmds)
  for _, cmd in ipairs(cmds) do
    OnEvents.set_one(plugin_name, "CmdUndefined", cmd)
  end
end

return M
