local OnEvents = require("optpack.core.loader.event")

local OnCommands = {}

function OnCommands.set(plugin_name, group_name, cmds)
  local events = vim
    .iter(cmds)
    :map(function(cmd)
      return { "CmdUndefined", cmd }
    end)
    :totable()
  OnEvents.set(plugin_name, group_name, events)
end

return OnCommands
