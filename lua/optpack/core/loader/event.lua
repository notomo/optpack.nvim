local M = {}

local OnEvents = {}
OnEvents.__index = OnEvents
M.OnEvents = OnEvents

function OnEvents.set(plugin_name, group_name, events)
  for _, event in ipairs(events) do
    local event_name
    local pattern = "*"
    if type(event) == "table" then
      event_name = event[1]
      pattern = event[2] or pattern
    else
      event_name = event
    end
    OnEvents._set(plugin_name, group_name, event_name, pattern)
  end
end

function OnEvents._set(plugin_name, group_name, event_name, pattern)
  vim.cmd(
    ([[autocmd %s %s %s ++once lua require("optpack").load(%q)]]):format(group_name, event_name, pattern, plugin_name)
  )
end

return M
