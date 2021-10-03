local M = {}

local OnEvents = {}
OnEvents.__index = OnEvents
M.OnEvents = OnEvents

function OnEvents.set(plugin_name, events)
  for _, event in ipairs(events) do
    local event_name
    local pattern = "*"
    if type(event) == "table" then
      event_name = event[1]
      pattern = event[2] or pattern
    else
      event_name = event
    end
    OnEvents.set_one(plugin_name, event_name, pattern)
  end
end

function OnEvents.set_one(plugin_name, event_name, pattern)
  vim.cmd(([[autocmd optpack %s %s ++once lua require("optpack.command").Command.new("load", %q)]]):format(event_name, pattern, plugin_name))
end

return M
