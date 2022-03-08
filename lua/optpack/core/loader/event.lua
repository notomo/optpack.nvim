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
    vim.api.nvim_create_autocmd({ event_name }, {
      group = group_name,
      pattern = { pattern },
      callback = function()
        require("optpack").load(plugin_name)
      end,
    })
  end
end

return M
