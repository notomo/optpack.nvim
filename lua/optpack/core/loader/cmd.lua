local OnEvents = require("optpack.core.loader.event").OnEvents

local M = {}

local OnCommands = {}
OnCommands.__index = OnCommands
M.OnCommands = OnCommands

function OnCommands.set(plugin_name, group_name, cmds)
  local events = vim.tbl_map(function(cmd)
    return { "CmdUndefined", cmd }
  end, cmds)
  OnEvents.set(plugin_name, group_name, events)
end

return M
